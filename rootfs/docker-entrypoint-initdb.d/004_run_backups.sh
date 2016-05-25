#!/usr/bin/env bash

# Create a fresh backup as a starting point
gosu postgres backup-initial &

# Run periodic backups in the background
gosu postgres backup &
