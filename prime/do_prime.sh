#!/bin/sh

# --- initialize from blank slate

echo 'Shutdown netops'
sudo service netops stop

echo 'Prime my DB'
mysql -uroot my <./my_prime.sql

echo 'Prime Netops DB'
mysql -uroot netops <./netops_prime.sql

echo 'Loading pins'
echo 'DELETE FROM `pins`; ALTER TABLE `pins` AUTO_INCREMENT=1;' | mysql -uroot my
mysql -uroot my <../../gen/rails/my/db/pin.sql

