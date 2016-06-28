#!/usr/bin/env bash

set -eof pipefail

puts-step() {
  echo "-----> $@"
}

puts-error() {
  echo "!!!    $@"
}

kill-containers() {
	puts-step "destroying containers"
	docker rm -f "$MINIO_JOB" "$PG_JOB"
}

# make sure we are in this dir
CURRENT_DIR=$(cd $(dirname $0); pwd)

puts-step "creating fake postgres credentials"

# create fake postgres credentials
mkdir -p $CURRENT_DIR/tmp/creds
echo "testuser" > $CURRENT_DIR/tmp/creds/user
echo "icanttellyou" > $CURRENT_DIR/tmp/creds/password

puts-step "creating fake minio credentials"

# create fake AWS credentials for minio admin credentials
mkdir -p $CURRENT_DIR/tmp/aws-admin
# needs to be 20 characters long
echo "12345678901234567890" > $CURRENT_DIR/tmp/aws-admin/access-key-id
# needs to be 40 characters long
echo "1234567890123456789012345678901234567890" > $CURRENT_DIR/tmp/aws-admin/access-secret-key

# create fake AWS credentials for minio user credentials
mkdir -p $CURRENT_DIR/tmp/aws-user
# needs to be 20 characters long
echo "12345678901234567890" > $CURRENT_DIR/tmp/aws-user/accesskey
echo "12345678901234567890" > $CURRENT_DIR/tmp/aws-user/access-key-id
# needs to be 40 characters long
echo "1234567890123456789012345678901234567890" > $CURRENT_DIR/tmp/aws-user/secretkey
echo "1234567890123456789012345678901234567890" > $CURRENT_DIR/tmp/aws-user/access-secret-key

puts-step "creating fake kubernetes service account token"

# create fake k8s serviceaccount token for minio to "discover" itself
mkdir -p $CURRENT_DIR/tmp/k8s
echo "token" > $CURRENT_DIR/tmp/k8s/token
echo "cert" > $CURRENT_DIR/tmp/k8s/ca.crt

# boot minio
MINIO_JOB=$(docker run -dv $CURRENT_DIR/tmp/aws-admin:/var/run/secrets/deis/minio/admin -v $CURRENT_DIR/tmp/aws-user:/var/run/secrets/deis/minio/user -v $CURRENT_DIR/tmp/k8s:/var/run/secrets/kubernetes.io/serviceaccount quay.io/deisci/minio:canary boot server /home/minio/)

# boot postgres, linking the minio container and setting DEIS_MINIO_SERVICE_HOST and DEIS_MINIO_SERVICE_PORT
PG_JOB=$(docker run -d --link $MINIO_JOB:minio -e BACKUP_FREQUENCY=1s -e DATABASE_STORAGE=minio -e DEIS_MINIO_SERVICE_HOST=minio -e DEIS_MINIO_SERVICE_PORT=9000 -v $CURRENT_DIR/tmp/creds:/var/run/secrets/deis/database/creds -v $CURRENT_DIR/tmp/aws-user:/var/run/secrets/deis/objectstore/creds $1)

# kill containers when this script exits or errors out
trap kill-containers INT TERM

# wait for postgres to boot
puts-step "sleeping for 90s while postgres is booting..."
sleep 90s

# display logs for debugging purposes
puts-step "displaying minio logs"
docker logs $MINIO_JOB
puts-step "displaying postgres logs"
docker logs $PG_JOB

# check if postgres is running
puts-step "checking if postgres is running"
docker exec $PG_JOB is_running

# check if minio has the 5 backups
puts-step "checking if minio has 5 backups"
BACKUPS="$(docker exec $MINIO_JOB ls /home/minio/dbwal/basebackups_005/ | grep json)"
NUM_BACKUPS="$(docker exec $MINIO_JOB ls /home/minio/dbwal/basebackups_005/ | grep -c json)"
# NOTE (bacongobbler): the BACKUP_FREQUENCY is only 1 second, so we could technically be checking
# in the middle of a backup. Instead of failing, let's consider N+1 backups an acceptable case
if [[ ! "$NUM_BACKUPS" -eq "5" && ! "$NUM_BACKUPS" -eq "6" ]]; then
  puts-error "did not find 5 or 6 base backups. 5 is the default, but 6 may exist if a backup is currently in progress (found $NUM_BACKUPS)"
  puts-error "$BACKUPS"
  exit 1
fi

# kill off postgres, then reboot and see if it's running after recovering from backups
puts-step "shutting off postgres, then rebooting to test data recovery"
docker rm -f $PG_JOB
PG_JOB=$(docker run -d --link $MINIO_JOB:minio -e BACKUP_FREQUENCY=1s -e DATABASE_STORAGE=minio -e DEIS_MINIO_SERVICE_HOST=minio -e DEIS_MINIO_SERVICE_PORT=9000 -v $CURRENT_DIR/tmp/creds:/var/run/secrets/deis/database/creds -v $CURRENT_DIR/tmp/aws-user:/var/run/secrets/deis/objectstore/creds $1)

# wait for postgres to boot
puts-step "sleeping for 90s while postgres is recovering from backup..."
sleep 90s

puts-step "displaying postgres logs"
docker logs $PG_JOB

# check if postgres is running
puts-step "checking if postgres is running"
docker exec $PG_JOB is_running
