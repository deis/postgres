#!/usr/bin/env bash

cd "$WALE_ENVDIR"

if [[ "$DATABASE_STORAGE" == "s3" || "$DATABASE_STORAGE" == "minio" ]]; then
  AWS_ACCESS_KEY_ID=$(cat /var/run/secrets/deis/objectstore/creds/accesskey)
  AWS_SECRET_ACCESS_KEY=$(cat /var/run/secrets/deis/objectstore/creds/secretkey)
  if [[ "$DATABASE_STORAGE" == "s3" ]]; then
    AWS_REGION=$(cat /var/run/secrets/deis/objectstore/creds/region)
    BUCKET_NAME=$(cat /var/run/secrets/deis/objectstore/creds/database-bucket)
  else
    AWS_REGION="us-east-1"
    BUCKET_NAME="dbwal"
    # these only need to be set if we're not accessing S3 (boto will figure this out)
    echo "http+path://$DEIS_MINIO_SERVICE_HOST:$DEIS_MINIO_SERVICE_PORT" > WALE_S3_ENDPOINT
    echo "$DEIS_MINIO_SERVICE_HOST" > S3_HOST
    echo "$DEIS_MINIO_SERVICE_PORT" > S3_PORT
    # enable sigv4 authentication
    echo "true" > S3_USE_SIGV4
  fi
  echo "s3://$BUCKET_NAME" > WALE_S3_PREFIX
  echo $AWS_ACCESS_KEY_ID > AWS_ACCESS_KEY_ID
  echo $AWS_SECRET_ACCESS_KEY > AWS_SECRET_ACCESS_KEY
  echo $AWS_REGION > AWS_REGION
  echo $BUCKET_NAME > BUCKET_NAME
elif [ "$DATABASE_STORAGE" == "gcs" ]; then
  GS_APPLICATION_CREDS="/var/run/secrets/deis/objectstore/creds/key.json"
  BUCKET_NAME=$(cat /var/run/secrets/deis/objectstore/creds/database-bucket)
  echo "gs://$BUCKET_NAME" > WALE_GS_PREFIX
  echo $GS_APPLICATION_CREDS > GS_APPLICATION_CREDS
  echo $BUCKET_NAME > BUCKET_NAME
elif [ "$DATABASE_STORAGE" == "azure" ]; then
  WABS_ACCOUNT_NAME=$(cat /var/run/secrets/deis/objectstore/creds/accountname)
  WABS_ACCESS_KEY=$(cat /var/run/secrets/deis/objectstore/creds/accountkey)
  BUCKET_NAME=$(cat /var/run/secrets/deis/objectstore/creds/database-container)
  echo $WABS_ACCOUNT_NAME > WABS_ACCOUNT_NAME
  echo $WABS_ACCESS_KEY > WABS_ACCESS_KEY
  echo "wabs://$BUCKET_NAME" > WALE_WABS_PREFIX
  echo $BUCKET_NAME > BUCKET_NAME
elif [ "$DATABASE_STORAGE" == "swift" ]; then
  SWIFT_USER=$(cat /var/run/secrets/deis/objectstore/creds/username)
  SWIFT_PASSWORD=$(cat /var/run/secrets/deis/objectstore/creds/password)
  SWIFT_TENANT=$(cat /var/run/secrets/deis/objectstore/creds/tenant)
  SWIFT_AUTHURL=$(cat /var/run/secrets/deis/objectstore/creds/authurl)
  SWIFT_AUTH_VERSION=$(cat /var/run/secrets/deis/objectstore/creds/authversion)
  BUCKET_NAME=$(cat /var/run/secrets/deis/objectstore/creds/database-container)
  # set defaults for variables that we can guess at
  echo $SWIFT_USER > SWIFT_USER
  echo $SWIFT_PASSWORD > SWIFT_PASSWORD
  echo $SWIFT_TENANT > SWIFT_TENANT
  echo $SWIFT_AUTHURL > SWIFT_AUTHURL
  echo $SWIFT_AUTH_VERSION > SWIFT_AUTH_VERSION
  echo "swift://$BUCKET_NAME" > WALE_SWIFT_PREFIX
  echo $BUCKET_NAME > BUCKET_NAME
fi
