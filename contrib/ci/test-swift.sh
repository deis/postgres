#!/usr/bin/env bash

set -eof pipefail

cleanup() {
  kill-containers "${SWIFT_DATA}" "${SWIFT_JOB}" "${PG_JOB}"
}
trap cleanup EXIT

TEST_ROOT=$(dirname "${BASH_SOURCE[0]}")/
# shellcheck source=/dev/null
source "${TEST_ROOT}/test.sh"

# make sure we are in this dir
CURRENT_DIR=$(cd "$(dirname "$0")"; pwd)

create-postgres-creds

puts-step "fetching openstack credentials"

# turn creds into something that we can use.
mkdir -p "${CURRENT_DIR}"/tmp/swift

# guess which value to use for tenant:
TENANT=""

echo "test:tester" > "${CURRENT_DIR}"/tmp/swift/username
echo "testing" > "${CURRENT_DIR}"/tmp/swift/password
echo "${TENANT}" > "${CURRENT_DIR}"/tmp/swift/tenant
echo "http://swift:8080/auth/v1.0" > "${CURRENT_DIR}"/tmp/swift/authurl
echo "1" > "${CURRENT_DIR}"/tmp/swift/authversion
echo "deis-swift-test" > "${CURRENT_DIR}"/tmp/swift/database-container

# boot swift
SWIFT_DATA=$(docker run -d -v /srv --name SWIFT_DATA busybox)

SWIFT_JOB=$(docker run -d --name onlyone --hostname onlyone --volumes-from SWIFT_DATA -t deis/swift-onlyone:git-8516d23)

# postgres container command
PG_CMD="docker run -d --link ${SWIFT_JOB}:swift -e BACKUP_FREQUENCY=3s \
   -e DATABASE_STORAGE=swift \
   -e PGCTLTIMEOUT=1200 \
   -v ${CURRENT_DIR}/tmp/creds:/var/run/secrets/deis/database/creds \
   -v ${CURRENT_DIR}/tmp/swift:/var/run/secrets/deis/objectstore/creds \
   $1"

start-postgres "$PG_CMD"

# display logs for debugging purposes
puts-step "displaying swift logs"
docker logs "${SWIFT_JOB}"

check-postgres "${PG_JOB}"

# check if swift has some backups ... 3 ?
puts-step "checking if swift has at least 3 backups"

BACKUPS="$(docker exec "${SWIFT_JOB}" swift -A http://127.0.0.1:8080/auth/v1.0 \
  -U test:tester -K testing list deis-swift-test | grep basebackups_005 | grep json)"
NUM_BACKUPS="$(echo "${BACKUPS}" | wc -w)"
# NOTE (bacongobbler): the BACKUP_FREQUENCY is only 1 second, so we could technically be checking
# in the middle of a backup. Instead of failing, let's consider N+1 backups an acceptable case
if [[ ! "${NUM_BACKUPS}" -eq "5" && ! "${NUM_BACKUPS}" -eq "6" ]]; then
  puts-error "did not find 5 or 6 base backups. 5 is the default, but 6 may exist if a backup is currently in progress (found $NUM_BACKUPS)"
  puts-error "${BACKUPS}"
  exit 1
fi

# kill off postgres, then reboot and see if it's running after recovering from backups
puts-step "shutting off postgres, then rebooting to test data recovery"
kill-containers "${PG_JOB}"

start-postgres "${PG_CMD}"

check-postgres "${PG_JOB}"

puts-step "tests PASSED!"
exit 0
