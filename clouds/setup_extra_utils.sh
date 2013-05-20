#!/bin/sh

echo 'Extra Utils...'

REQUIRED_PACKAGES="\
    telnet-0.17-47.el6_3.1                      \
    "
sudo yum install -y $REQUIRED_PACKAGES || exit -1

SAVE=$PWD

NGREP=ngrep-1.45-2.el6.rf.x86_64.rpm 
cd /tmp/
wget http://pkgs.repoforge.org/ngrep/$NGREP
sudo rpm -ivh $NGREP

cd $SAVE

exit 0

