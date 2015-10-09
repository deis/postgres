#!/usr/bin/env python

import sys, os, yaml, time, urllib2, atexit
import logging

from helpers.keystore import Etcd
from helpers.postgresql import Postgresql
from helpers.ha import Ha


logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s', level=logging.INFO)

f = open(sys.argv[1], "r")
config = yaml.load(f.read())
f.close()

# HACK (bacongobbler): kubernetes provides us with etcd's host/port info
config['etcd']['host'] = "{}:{}".format(
    os.getenv("ETCD_SERVICE_HOST", "127.0.0.1"),
    os.getenv("ETCD_SERVICE_PORT", 4001))
etcd = Etcd(config['etcd'])
postgresql = Postgresql(config["postgresql"])
ha = Ha(postgresql, etcd)

logging.info("my name is {}".format(postgresql.name))

# stop governor on script exit
def stop_governor():
    postgresql.stop()
atexit.register(stop_governor)

# wait for etcd to be available
etcd_ready = False
while not etcd_ready:
    try:
        etcd.touch_member(postgresql.name, postgresql.connection_string)
        etcd_ready = True
    except urllib2.URLError as e:
        logging.info("waiting on etcd: {}".format(e))
        time.sleep(5)

# is data directory empty?
if postgresql.data_directory_empty():
    # racing to initialize
    if etcd.race("/initialize", postgresql.name):
        postgresql.initialize()
        etcd.take_leader(postgresql.name)
        postgresql.start()
    else:
        synced_from_leader = False
        while not synced_from_leader:
            leader = etcd.current_leader()
            if not leader:
                logging.info("leader is starting up. Checking again in 5 seconds")
                time.sleep(5)
                continue
            if postgresql.sync_from_leader(leader):
                postgresql.write_recovery_conf(leader)
                postgresql.fix_data_dir_permissions()
                postgresql.start()
                synced_from_leader = True
            else:
                time.sleep(5)
else:
    postgresql.follow_no_leader()
    postgresql.start()

while True:
    logging.info(ha.run_cycle())

    # create replication slots
    if postgresql.is_leader():
        for member in etcd.members():
            member = member['hostname']
            if member != postgresql.name:
                postgresql.query("DO LANGUAGE plpgsql $$DECLARE somevar VARCHAR; BEGIN SELECT slot_name INTO somevar FROM pg_replication_slots WHERE slot_name = '%(slot)s' LIMIT 1; IF NOT FOUND THEN PERFORM pg_create_physical_replication_slot('%(slot)s'); END IF; END$$;" % {"slot": member})

    # HACK (bacongobbler): kubernetes provides us with the service's host ip addr
    connection_string = postgresql.connection_string.replace(postgresql.host, os.getenv("DEIS_POSTGRES_SERVICE_HOST")).replace(postgresql.port, os.getenv("DEIS_POSTGRES_SERVICE_PORT"))
    etcd.touch_member(postgresql.name, connection_string)

    time.sleep(config["loop_wait"])
