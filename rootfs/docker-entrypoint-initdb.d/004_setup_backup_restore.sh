#!/usr/bin/env bash

# docker-entrypoint.sh will apply this config when it reboots the server after these
# scripts have finished running
cat << EOF >> "$PGDATA/postgresql.conf"
archive_mode = on
archive_command = 'envdir "${WALE_ENVDIR}" wal-e wal-push %p'
archive_timeout = 60
EOF

# once again, ensure $PGDATA has the right permissions
chown -R postgres:postgres "$PGDATA"
chmod 0700 "$PGDATA"
