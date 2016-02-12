#!/usr/bin/env bash

set -eof pipefail
set -x

JOB=$(docker run -d $1)
# wait for postgres to boot
CURRENT_DIR=$(cd $(dirname $0); pwd)
mkdir -p tmp
echo "testuser" > tmp/user
echo "icanttellyou" > tmp/pass
JOB=$(docker run -dv $CURRENT_DIR/tmp:/etc/secret-volume $1)
# wait for postgres to boot
sleep 10
docker exec $JOB is_master
docker rm -f $JOB
