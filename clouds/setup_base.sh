#!/bin/sh

echo 'Base System...'

# fixup yum repository for older packages
cat <<'EOT' >/tmp/CentOS-Vault-6-3.repo
# BR find older packages

[C6.3-base]
name=CentOS-6.3 - Base
baseurl=http://vault.centos.org/6.3/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1

[C6.3-updates]
name=CentOS-6.3 - Updates
baseurl=http://vault.centos.org/6.3/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1

[C6.3-extras]
name=CentOS-6.3 - Extras
baseurl=http://vault.centos.org/6.3/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1

[C6.3-contrib]
name=CentOS-6.3 - Contrib
baseurl=http://vault.centos.org/6.3/contrib/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1

[C6.3-centosplus]
name=CentOS-6.3 - CentOSPlus
baseurl=http://vault.centos.org/6.3/centosplus/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1
EOT
sudo install -o root -m 644 /tmp/CentOS-Vault-6-3.repo /etc/yum.repos.d

# purge bookstrapping temporary git
sudo rm -f /usr/bin/git

# note some of these may already be installed depending on how minimal our minimal OS base was
REQUIRED_PACKAGES="\
    git-1.7.1-2.el6_0.1                         \
    perl-Error-0.17015-4.el6                    \
    perl-Git-1.7.1-2.el6_0.1                    \
    perl-JSON-2.15-5.el6                        \
    perl-IO-Compress-Base-2.020-127.el6         \
    perl-IO-Compress-Zlib-2.020-127.el6         \
    perl-Compress-Raw-Zlib-2.020-127.el6        \
    perl-Compress-Zlib-2.020-127.el6            \
    kernel-2.6.32-279.1.1.el6                   \
    kernel-firmware-2.6.32-279.1.1.el6          \
    ntp-4.2.4p8-2.el6.centos                    \
    "
sudo yum install -y $REQUIRED_PACKAGES || exit -1

# just say no
sudo /sbin/chkconfig postfix && sudo /sbin/chkconfig postfix off
sudo /sbin/chkconfig cups && sudo /sbin/chkconfig cups off

# but say yes
sudo /sbin/chkconfig ntpd on # auto startup of ntp

exit 0

