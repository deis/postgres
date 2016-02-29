#!/usr/bin/env bash

cd "$WALE_ENVDIR"

# access-key-id and access-secret-key files are mounted in via kubernetes secrets
if [ "$DATABASE_STORAGE" == "s3" ]; then
  AWS_ACCESS_KEY_ID=$(cat /var/run/secrets/deis/objectstore/creds/accesskey)
  AWS_SECRET_ACCESS_KEY=$(cat /var/run/secrets/deis/objectstore/creds/secretkey)
  AWS_DEFAULT_REGION=$(cat /var/run/secrets/deis/objectstore/creds/region)
  BUCKET_NAME=$(cat /var/run/secrets/deis/objectstore/creds/database-bucket)
  echo $AWS_ACCESS_KEY_ID > AWS_ACCESS_KEY_ID
  echo $AWS_SECRET_ACCESS_KEY > AWS_SECRET_ACCESS_KEY
  echo $BUCKET_NAME > BUCKET_NAME
else
  AWS_ACCESS_KEY_ID=$(cat access-key-id)
  AWS_SECRET_ACCESS_KEY=$(cat access-secret-key)
  AWS_DEFAULT_REGION="us-east-1"
  BUCKET_NAME="dbwal"
  echo "http://$DEIS_MINIO_SERVICE_HOST:$DEIS_MINIO_SERVICE_PORT" > WALE_S3_ENDPOINT
  echo "http://$DEIS_MINIO_SERVICE_HOST:$DEIS_MINIO_SERVICE_PORT" > S3_URL
  cp access-key-id AWS_ACCESS_KEY_ID
  cp access-secret-key AWS_SECRET_ACCESS_KEY
  echo $BUCKET_NAME > BUCKET_NAME
fi

# setup envvars for wal-e
echo "s3://$BUCKET_NAME" > WALE_S3_PREFIX


# setup boto config
mkdir -p /root/.aws /home/postgres/.aws

cat << EOF > /root/.aws/credentials
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF

# HACK (bacongobbler): minio *must* use us-east-1 and signature version 4
# for authentication.
# see https://github.com/minio/minio#how-to-use-aws-cli-with-minio
if [ "$DATABASE_STORAGE" == "s3" ]; then
cat << EOF > /root/.aws/config
[default]
region = $AWS_DEFAULT_REGION
EOF
else
cat << EOF > /root/.aws/config
[default]
region = $AWS_DEFAULT_REGION
s3 =
    signature_version = s3v4
EOF
fi


# write AWS config to postgres homedir as well
cp /root/.aws/* /home/postgres/.aws/
chown -R postgres:postgres /home/postgres
