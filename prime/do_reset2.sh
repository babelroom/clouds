#!/bin/sh

br --offline;

sudo service mysqld start

echo "drop database my" | /usr/bin/mysql -uroot
echo "drop database netops" | /usr/bin/mysql -uroot

sudo service mysqld stop

rm /home/br/gits/clouds/gen/rails/my/config/initializers/session_store.rb
sudo rm -f /var/estream/data/fs_map/*/*
sudo rm -f /var/estream/data/q/*
sudo touch /var/estream/data/q/_status

#sudo rm -f /var/estream/log/*
#sudo rm -f /home/br/gits/clouds/netops/log/*
sudo rm -f /var/log/br/*/*

sudo find /var/log/br -type f -exec rm -f {} \;

cd /home/br/gits/clouds/clouds

./setup_db.sh

