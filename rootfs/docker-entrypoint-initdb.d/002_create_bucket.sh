#!/usr/bin/env bash

# ensure WAL log bucket exists
envdir "$WALE_ENVDIR" create_bucket "$BUCKET_NAME"
