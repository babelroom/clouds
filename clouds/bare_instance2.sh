#!/bin/sh

echo ---
echo 'Bare instance - phase 2'
echo ---

sudo useradd br
sudo passwd -d br # no password

sudo sh -c 'echo -e "\n# AUTO by bare_instance2.sh\nbr ALL = NOPASSWD: ALL\n" >/etc/sudoers.d/br'
# the following generates an ironic warning
sudo chmod 440 /etc/sudoers.d/br

sudo mkdir -m 755 -p /var/log/br && sudo chown br:br /var/log/br

echo 'starting bare_instance3.sh'
su br --session-command=./bare_instance3.sh     # stops ssh from complaining b/c no stdin

