#!/bin/sh

echo 'MySQL (client) / MySQL devel'

test -x /usr/bin/mysql && echo 'Already installed!' && exit 0;

./setup_openssl_devel.sh || exit -1

REQUIRED_PACKAGES="\
    mysql-5.1.66-2.el6_3                        \
    mysql-libs-5.1.66-2.el6_3                   \
    mysql-devel-5.1.66-2.el6_3                  \
    mysql-5.1.66-2.el6_3                        \
    mysql-libs-5.1.66-2.el6_3                   \
    "
sudo yum install -y $REQUIRED_PACKAGES || exit -1

exit 0

