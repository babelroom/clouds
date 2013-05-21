#!/bin/sh

# --- stop everything (at least all services that are well behaved), exclude mysqldb
sudo service netops stop
sudo service node_app stop
sudo service mongrel_my stop
sudo service mongrel_no stop
sudo service estream stop
sudo service freeswitch stop
sudo service red5 stop
sudo service nginx stop
sudo service fail2ban stop

