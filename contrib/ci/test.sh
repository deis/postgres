#!/usr/bin/env bash

set -eof pipefail

puts-step() {
  echo "-----> $@"
}

puts-error() {
  echo "!!!    $@"
}

# make sure we are in this dir
CURRENT_DIR=$(cd $(dirname $0); pwd)

puts-step "creating fake database credentials"

# create fake database credentials
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
echo "12345678901234567890" > $CURRENT_DIR/tmp/aws-user/access-key-id
# needs to be 40 characters long
echo "1234567890123456789012345678901234567890" > $CURRENT_DIR/tmp/aws-user/access-secret-key

puts-step "creating fake kubernetes service account token"

# create fake k8s serviceaccount token for minio to "discover" itself
mkdir -p $CURRENT_DIR/tmp/k8s
echo "token" > $CURRENT_DIR/tmp/k8s/token
echo "cert" > $CURRENT_DIR/tmp/k8s/ca.crt

# boot minio
MINIO_JOB=$(docker run -dv $CURRENT_DIR/tmp/aws-admin:/var/run/secrets/deis/minio/admin -v $CURRENT_DIR/tmp/aws-user:/var/run/secrets/deis/minio/user -v $CURRENT_DIR/tmp/k8s:/var/run/secrets/kubernetes.io/serviceaccount quay.io/deisci/minio:canary boot server /home/minio/)

# boot postgres, linking the minio container and setting DEIS_MINIO_SERVICE_HOST and DEIS_MINIO_SERVICE_PORT
PG_JOB=$(docker run -d --link $MINIO_JOB:minio -e BACKUP_FREQUENCY=1s -e DEIS_MINIO_SERVICE_HOST=minio -e DEIS_MINIO_SERVICE_PORT=9000 -v $CURRENT_DIR/tmp/creds:/var/run/secrets/deis/database/creds -v $CURRENT_DIR/tmp/aws-user:/etc/wal-e.d/env $1)

# wait for postgres to boot
puts-step "sleeping for 90s while postgres is booting..."
sleep 90s

# display logs for debugging purposes
puts-step "displaying minio logs"
docker logs $MINIO_JOB
puts-step "displaying database logs"
docker logs $PG_JOB

# check if postgres is running
puts-step "checking if database is running"
docker exec $PG_JOB is_running

# check if minio has the 5 backups
puts-step "checking if minio has 5 backups"
NUM_BACKUPS="$(docker exec $MINIO_JOB ls /home/minio/dbwal/basebackups_005/ | grep json | wc -l)"
if [[ ! "$NUM_BACKUPS" -eq "5" ]]; then
  puts-error "did not find 5 base backups, which is the default (found $NUM_BACKUPS)"
  exit 1
fi

# success, kill off jobs
puts-step "destroying containers"
docker rm -f $MINIO_JOB
docker rm -f $PG_JOB
