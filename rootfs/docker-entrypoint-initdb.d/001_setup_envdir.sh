#!/usr/bin/env bash

cd "$WALE_ENVDIR"

# access-key-id and access-secret-key files are mounted in via kubernetes secrets
AWS_ACCESS_KEY_ID=$(cat access-key-id)
AWS_SECRET_ACCESS_KEY=$(cat access-secret-key)
AWS_DEFAULT_REGION="us-east-1"
BUCKET_NAME="dbwal"

if [ "$DATABASE_STORAGE" == "s3" ]; then
  AWS_ACCESS_KEY_ID=$(cat /var/run/secrets/deis/objectstore/creds/accesskey)
  AWS_SECRET_ACCESS_KEY=$(cat /var/run/secrets/deis/objectstore/creds/secretkey)
  AWS_DEFAULT_REGION=$(cat /var/run/secrets/deis/objectstore/creds/region)
  BUCKET_NAME=$(cat /var/run/secrets/deis/objectstore/creds/database-bucket)
else
  # these only need to be set if we're not accessing S3 (boto will figure this out)
  echo "http://$DEIS_MINIO_SERVICE_HOST:$DEIS_MINIO_SERVICE_PORT" > WALE_S3_ENDPOINT
  if [ "$DEIS_MINIO_SERVICE_PORT" == "80" ]; then
    # If you add port 80 to the end of the endpoint_url, boto3 freaks out.
    # God I hate boto3 some days.
    echo "http://$DEIS_MINIO_SERVICE_HOST" > S3_URL
  elif [ "$DEIS_MINIO_SERVICE_PORT" == "443" ]; then
    echo "https://$DEIS_MINIO_SERVICE_HOST" > S3_URL
  else
    echo "http://$DEIS_MINIO_SERVICE_HOST:$DEIS_MINIO_SERVICE_PORT" > S3_URL
  fi
fi

echo $AWS_ACCESS_KEY_ID > AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY > AWS_SECRET_ACCESS_KEY
echo $AWS_DEFAULT_REGION > AWS_DEFAULT_REGION
echo $BUCKET_NAME > BUCKET_NAME

# setup envvars for wal-e
echo "s3://$BUCKET_NAME" > WALE_S3_PREFIX


# setup boto config
mkdir -p /root/.aws /home/postgres/.aws

cat << EOF > /root/.aws/credentials
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF

if [ "$DATABASE_STORAGE" == "s3" ]; then
  cat << EOF > /root/.aws/config
[default]
region = $AWS_DEFAULT_REGION
EOF
else
  # HACK (bacongobbler): minio *must* use us-east-1 and signature version 4
  # for authentication.
  # see https://github.com/minio/minio#how-to-use-aws-cli-with-minio
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
