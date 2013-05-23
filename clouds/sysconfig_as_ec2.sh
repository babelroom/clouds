#!/bin/sh

# the following makes the minimal ISO install the same as our amazon image
BBRF=orig_before_br
cd /etc/selinux
sudo mv config config.$BBRF
cd /etc/sysconfig
sudo mkdir $BBRF
sudo mv ip*tables* system-config-firewall* $BBRF
cd /tmp/gits.tmp/clouds/clouds/misc/sysconfig
sudo install -o root -m 644 config /etc/selinux
sudo install -o root -m 600 system-config-firewall /etc/sysconfig

exit 0

