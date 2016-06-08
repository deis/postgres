#!/usr/bin/env bash

# Run periodic backups in the background
gosu postgres backup &
