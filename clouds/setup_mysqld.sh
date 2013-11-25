#!/bin/sh

echo '| MySQL | (this should leave us with version 5.1.66)'

test -d /var/log/br/mysql && echo 'Already installed!' && exit 0;

./setup_mysql_client.sh || exit -1

REQUIRED_PACKAGES="\
    mysql-server-5.1.66-2.el6_3                 \
    perl-DBD-MySQL-4.013-3.el6                  \
    perl-DBI-1.609-4.el6                        \
    "
sudo yum install -y $REQUIRED_PACKAGES || exit -1

LOGDIR=/var/log/br/mysql
sudo mkdir $LOGDIR && sudo chown mysql:mysql $LOGDIR

cat <<EOT >/home/br/tmp/my.cnf
# default BR configuration, may be replaced by version from primer
[mysqld]
bind-address=127.0.0.1
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql

# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0

# character set stuff
character-set-server = utf8
collation-server = utf8_general_ci
init-connect='SET NAMES utf8'

long_query_time=1
slow_query_log_file=$LOGDIR/log-slow-queries.log

#general_log_file=$LOGDIR/mysql.log
#general_log=1

#server-id=7
#log-bin=binlog
#binlog-format=ROW


[mysqld_safe]
log-error=$LOGDIR/error.log
pid-file=$LOGDIR/mysqld.pid

EOT

sudo cp -a /etc/my.cnf /etc/my.cnf-orig
sudo cp /home/br/tmp/my.cnf /etc/my.cnf

exit 0

