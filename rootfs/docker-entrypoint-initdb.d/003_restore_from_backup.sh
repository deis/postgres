#!/usr/bin/env bash

cat << EOF >> "$PGDATA/postgresql.conf"
wal_level = archive
EOF

# check if there are any backups -- if so, let's restore
# we could probably do better than just testing number of lines -- one line is just a heading, meaning no backups
if [[ $(envdir "$WALE_ENVDIR" wal-e --terse backup-list | wc -l) -gt "1" ]]; then
  echo "Found backups on S3. Restoring from backup..."
  rm -rf "$PGDATA"
  envdir "$WALE_ENVDIR" wal-e backup-fetch "$PGDATA" LATEST
  cat << EOF > "$PGDATA/postgresql.conf"
# These settings are initialized by initdb, but they can be changed.
log_timezone = 'UTC'
lc_messages = 'C'     # locale for system error message
lc_monetary = 'C'     # locale for monetary formatting
lc_numeric = 'C'      # locale for number formatting
lc_time = 'C'       # locale for time formatting
default_text_search_config = 'pg_catalog.english'
wal_level = archive
listen_addresses = '*'
EOF
  cat << EOF > "$PGDATA/pg_hba.conf"
# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# IPv4 global connections
host    all             all             0.0.0.0/0               md5
EOF
  touch "$PGDATA/pg_ident.conf"
  echo "restore_command = 'envdir /etc/wal-e.d/env wal-e wal-fetch \"%f\" \"%p\"'" >> "$PGDATA/recovery.conf"
  echo "Done restoring from backup"
else
  echo "No backups found. Booting postgres to perform an initial backup..."
  gosu postgres pg_ctl -o "-c listen-addresses=''" -w start
  echo "Performing an initial backup..."
  gosu postgres envdir "$WALE_ENVDIR" wal-e backup-push "$PGDATA"
  echo "Shutting down, then continuing with the rest of the bootstrap process."
  gosu postgres pg_ctl -w stop
fi

cat << EOF >> "$PGDATA/postgresql.conf"
archive_mode = on
archive_command = 'envdir "${WALE_ENVDIR}" wal-e wal-push %p'
archive_timeout = 60
EOF

# ensure $PGDATA has the right permissions
chown -R postgres:postgres "$PGDATA"
chmod 0700 "$PGDATA"
