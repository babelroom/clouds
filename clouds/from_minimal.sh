#!/bin/sh

# ---
# Raise a CentOS6.3 bare install to the point where it can run BR setups
# ---

# ---
# run it on a CentOS minimal install as follows:
# $ curl -O https://raw.githubusercontent.com/babelroom/clouds/master/clouds/from_minimal.sh
# $ sh from_minimal.sh
# ---

cat <<'EOT' >/etc/yum.repos.d/from_minimal.repo
[from_minimal]
name=CentOS-6.3 - Base
baseurl=http://vault.centos.org/6.3/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1

EOT

yum --disablerepo=\* --enablerepo=from_minimal install -y sudo perl wget make
rm -f /etc/yum.repos.d/from_minimal.repo

#wget --no-check-certificate https://sourceforge.net/projects/babelroom/files/git-1.7.1.bin/download -O /usr/bin/git && chmod +x /usr/bin/git && mkdir /tmp/gits.tmp && cd /tmp/gits.tmp && git clone -b 2.38 git://github.com/babelroom/clouds.git && cd ./clouds/clouds && ./bare_instance2.sh && ./sysconfig_as_ec2.sh
wget --no-check-certificate https://sourceforge.net/projects/babelroom/files/git-1.7.1.bin/download -O /usr/bin/git && chmod +x /usr/bin/git && mkdir /tmp/gits.tmp && cd /tmp/gits.tmp && git clone git://github.com/babelroom/clouds.git && cd ./clouds/clouds && ./bare_instance2.sh && ./sysconfig_as_ec2.sh

