#!/bin/sh

br --offline;

sudo service mysqld start

echo "drop database my; drop database netops; quit;" | /usr/bin/mysql -uroot

sudo service mysqld stop

rm /home/br/gits/clouds/gen/rails/my/config/initializers/session_store.rb

cd /home/br/gits/clouds/clouds

./setup_db.sh

