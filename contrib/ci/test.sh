#!/usr/bin/env bash

set -eof pipefail
set -x

JOB=$(docker run -d $1)
# wait for postgres to boot
CURRENT_DIR=$(cd $(dirname $0); pwd)
mkdir -p $CURRENT_DIR/tmp
echo "testuser" > $CURRENT_DIR/tmp/user
echo "icanttellyou" > $CURRENT_DIR/tmp/password
JOB=$(docker run -dv $CURRENT_DIR/tmp:/var/run/secrets/deis/database/creds $1)
sleep 10
docker exec $JOB is_master
docker rm -f $JOB
