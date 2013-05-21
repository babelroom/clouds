#!/bin/sh

# --- initial setup (for after clouds/setup_all.sh)

echo 'Shutdown everything else...'
./do_stopall.sh

echo 'Re(start) DB'
sudo service mysqld stop
sudo service mysqld start

echo 'Create databases'
mysql -uroot <./create_dbs.sql

echo 'my DB'
#mysql -uroot my <./my_full_dump.sql
mysql -uroot my <./my_prime.sql

echo 'Netops DB'
#mysql -uroot netops <./netops_full_dump.sql
# this is a little inefficient WRT adding the set of pins twice
mysql -uroot netops <./netops_prime.sql

# assume the image may be older than source repository...
cd /home/br/gits/red5; git pull
cd /home/br/gits/eStream; git pull
cd /home/br/gits/FS; git pull
cd /home/br/gits/netops; git pull
cd /home/br/gits/gen; git pull

make clean
make

cd /home/br/gits/gen/rails/my
RAILS_ENV=production rake db:migrate

echo 'Load pins'    # need to do this after the DB has been migrated up
mysql -uroot my </home/br/gits/gen/rails/my/db/pin.sql

cd /home/br/gits/gen/rails/my/public
make clean
make

cd /home/br/gits/gen/rails/netops
RAILS_ENV=production rake db:migrate

# reset my master for binlog
echo 'RESET MASTER' | mysql -uroot my

# fixups after DB is migrated up
echo "UPDATE users SET email = 'demo@babelroom.com' WHERE id = 2;" | mysql -uroot my
echo "UPDATE users SET email = 'john@babelroom.com', api_key = '4d6233a64e2ba310f05bfe8f3a5091fe' WHERE id = 3;" | mysql -uroot my

