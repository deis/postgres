#!/usr/bin/env bash

set -eof pipefail

# kill containers when this script exits or errors out
trap exit-script INT TERM

puts-step() {
  echo "-----> $@"
}

puts-error() {
  echo "!!!    $@"
}

exit-script() {
  kill-containers
  kill-swift
}

kill-containers() {
  # docker containers
  puts-step "destroying postgres container"
  docker rm -f deis-postgres-swift
}

kill-swift() {
  # swift containers
  puts-step "cleaning swift"
  swift delete deis-swift-test > /dev/null
}

# make sure we are in this dir
CURRENT_DIR=$(cd $(dirname $0); pwd)

puts-step "creating fake postgres credentials"

# create fake postgres credentials
mkdir -p $CURRENT_DIR/tmp/creds
echo "testuser" > $CURRENT_DIR/tmp/creds/user
echo "icanttellyou" > $CURRENT_DIR/tmp/creds/password

puts-step "fetching openstack credentials"

# check if openstack creds are not already in environment
if [[ -z $OS_USERNAME ]]; then
  echo "it appears that you have not loaded your openstack credentials into your environment"
  exit 1
fi

# turn creds into something that we can use.
mkdir -p $CURRENT_DIR/tmp/swift

# guess which value to use for tenant:
TENANT=${OS_TENANT_NAME:-$OS_PROJECT_NAME}
TENANT=${TENANT:-$OS_USERNAME}

echo ${OS_USERNAME} > $CURRENT_DIR/tmp/swift/username
echo ${OS_PASSWORD} > $CURRENT_DIR/tmp/swift/password
echo ${TENANT} > $CURRENT_DIR/tmp/swift/tenant
echo ${OS_AUTH_URL} > $CURRENT_DIR/tmp/swift/authurl
echo "deis-swift-test" > $CURRENT_DIR/tmp/swift/database-container

# postgres container command
PG_CMD="docker run -d -e BACKUP_FREQUENCY=3s \
         -e DATABASE_STORAGE=swift \
         -v $CURRENT_DIR/tmp/creds:/var/run/secrets/deis/database/creds \
         -v $CURRENT_DIR/tmp/swift:/var/run/secrets/deis/objectstore/creds \
         $1"

# boot postgres
PG_JOB=$(${PG_CMD})

# wait for postgres to boot
puts-step "sleeping for 90s while postgres is booting..."
sleep 90s

# display logs for debugging purposes
puts-step "displaying postgres logs"
docker logs $PG_JOB

# check if postgres is running
puts-step "checking if postgres is running"
docker exec $PG_JOB is_running

# check if swift has some backups ... 3 ?
puts-step "checking if swift has at least 3 backups"

BACKUPS="$(swift list deis-swift-test | grep basebackups_005 | grep json)"
NUM_BACKUPS="$(swift list deis-swift-test | grep basebackups_005 | grep -c json)"
if [[ ! "$NUM_BACKUPS" -gt "3" ]]; then
  puts-error "did not find at least 3 base backups, which is the default (found $NUM_BACKUPS)"
  puts-error "$BACKUPS"
  exit-script
  exit 1
fi

puts-step "found $NUM_BACKUPS"

# kill off postgres, then reboot and see if it's running after recovering from backups
puts-step "shutting off postgres, then rebooting to test data recovery"
docker rm -f $PG_JOB
PG_JOB=$(${PG_CMD})

# wait for postgres to boot
puts-step "sleeping for 90s while postgres is recovering from backup..."
sleep 90s

puts-step "displaying postgres logs"
docker logs $PG_JOB

# check if postgres is running
puts-step "checking if postgres is running"
docker exec $PG_JOB is_running

puts-step "tests PASSED!"
exit 0
