#!/bin/sh

# --- reset working environment to initial state

echo 'Shutdown everything...'
./do_stopall.sh

echo 'Prime my DB'
mysql -uroot my <./my_prime.sql

echo 'Prime Netops DB'
mysql -uroot netops <./netops_prime.sql

echo 'Remove old conference and people pins from estream'
sudo rm -f /var/estream/data/fs_map/pin/*
sudo rm -f /var/estream/data/fs_map/phone/*
sudo rm -f /var/estream/data/fs_map/conference/*

echo 'Reset conference queues'
sudo rm -f /var/estream/data/q/*
sudo touch /var/estream/data/q/_status
sudo chmod 644 /var/estream/data/q/_status

echo 'Resetting pins...'
echo 'UPDATE `pins` SET updated_at=NOW(), invitation_id=NULL;' | mysql -uroot my

echo 'RESET MASTER;' | mysql -uroot
echo 'Stop DB'
sudo service mysqld stop

echo 'Delete replication marker'
sudo rm -f /home/br/gits/clouds/netops/replicate_db/provisioning*

echo 'Delete logfiles'
sudo rm -f /var/log/br/mysql/*
sudo rm -f /home/br/gits/clouds/netops/log/*
sudo rm -f /var/log/br/*.*
sudo rm -f /tmp/br/*

echo 'Delete extranious files'
sudo rm -f /cs_media/conf_recordings/*

