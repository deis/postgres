#!/usr/bin/env bash

cd "$WALE_ENVDIR"

if [[ "$DATABASE_STORAGE" == "s3" || "$DATABASE_STORAGE" == "minio" ]]; then
  AWS_ACCESS_KEY_ID=$(cat /var/run/secrets/deis/objectstore/creds/accesskey)
  AWS_SECRET_ACCESS_KEY=$(cat /var/run/secrets/deis/objectstore/creds/secretkey)
  if [[ "$DATABASE_STORAGE" == "s3" ]]; then
    AWS_DEFAULT_REGION=$(cat /var/run/secrets/deis/objectstore/creds/region)
    BUCKET_NAME=$(cat /var/run/secrets/deis/objectstore/creds/database-bucket)
  else
    # these only need to be set if we're not accessing S3 (boto will figure this out)
    echo "http://$DEIS_MINIO_SERVICE_HOST:$DEIS_MINIO_SERVICE_PORT" > WALE_S3_ENDPOINT
    if [ "$DEIS_MINIO_SERVICE_PORT" == "80" ]; then
      # If you add port 80 to the end of the endpoint_url, boto3 freaks out.
      # God I hate boto3 some days.
      echo "http://$DEIS_MINIO_SERVICE_HOST" > S3_URL
    else
      echo "http://$DEIS_MINIO_SERVICE_HOST:$DEIS_MINIO_SERVICE_PORT" > S3_URL
    fi
    AWS_DEFAULT_REGION="us-east-1"
    BUCKET_NAME="dbwal"
  fi
  echo "s3://$BUCKET_NAME" > WALE_S3_PREFIX
  echo $AWS_ACCESS_KEY_ID > AWS_ACCESS_KEY_ID
  echo $AWS_SECRET_ACCESS_KEY > AWS_SECRET_ACCESS_KEY
  echo $AWS_DEFAULT_REGION > AWS_DEFAULT_REGION
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
fi
