#!/bin/sh

echo 'Create DBs and their initial datasets...'
./setup_mysql_client.sh  || exit -1
echo "quit" | /usr/bin/mysql/mysql -uroot netops 2>/dev/null && echo "Already setup (netops DB exists)" && exit 0
./setup_rails.sh  || exit -1

# 1. start DB server temporarily
sudo service mysqld start

# 2. create DBs
mysql -uroot <$HOME/gits/clouds/prime/create_dbs.sql

# 3. rails migrate DBs
cd $HOME/gits/clouds/gen/rails/my
./install.sh 2>>/tmp/br/my.err
cd $HOME/gits/clouds/gen/rails/netops
./install.sh 2>>/tmp/br/netops.err

# 4. prime to populate
/usr/bin/mysql -uroot my <$HOME/gits/clouds/prime/my_prime.sql
/usr/bin/mysql -uroot netops <$HOME/gits/clouds/prime/netops_prime.sql

# 5. add PINS!!!!
echo 'Loading pins...'
echo 'DELETE FROM `pins`; ALTER TABLE `pins` AUTO_INCREMENT=1;' | mysql -uroot my
mysql -uroot my <$HOME/gits/clouds/gen/rails/my/db/pin.sql

# 6. reset master so binlog isn't sucking thru all this setup
echo "reset master;" | /usr/bin/mysql -uroot 

# 7. stop DB
sudo service mysqld stop

exit 0;

