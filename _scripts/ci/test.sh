#!/usr/bin/env bash

set -eof pipefail
set -x

JOB=$(docker run -d $1)
# wait for postgres to boot
sleep 4
docker exec $JOB is_master
docker rm -f $JOB
