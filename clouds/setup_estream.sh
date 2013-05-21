#!/bin/sh

echo 'eStream...'

test -d /usr/local/estream && echo 'Already installed!' && exit 0;

./setup_buildtools.sh || exit -1
./setup_openssl_devel.sh || exit -1

SAVE=$PWD
cd $HOME/gits/clouds/eStream
git pull || exit -1     # get latest version

# ---
make clean && make
sudo sh -c "cd $HOME/gits/clouds/eStream && make install"
make clean
sudo /sbin/chkconfig estream off        # make install puts this on by default, disable it as we'll use primers
sudo install -m 755 $HOME/gits/eStream/bin/rc /etc/init.d/estream

exit 0

