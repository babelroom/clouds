#!/bin/sh

# ref:
# http://www.bashton.com/blog/2012/how-to-make-your-own-centos-6-amis/

# ---
IFC=ifcfg-eth0
BBRF=orig_before_br

# the following makes the minimal ISO install the same as our amazon image
cd /etc/selinux
sudo mv config config.$BBRF
cd /etc/sysconfig
sudo mkdir $BBRF
sudo mv ip*tables* system-config-firewall* $BBRF
cd /tmp/gits.tmp/clouds/clouds/misc/sysconfig
sudo install -o root -m 644 config /etc/selinux
sudo install -o root -m 600 system-config-firewall /etc/sysconfig

# fixup ifcfg-eth0 -- (1) default to start on boot, and (2) drop the MAC address so udev doesn't rename eth0 to eth2 when a new MAC is assigned
cd /etc/sysconfig/network-scripts
sudo mv $IFC $IFC.$BBRF
sed '/HWADDR=.*/d' $IFC.$BBRF | sudo sed '/^ONBOOT="no"$/c' ONBOOT="yes" > $IFC

exit 0

