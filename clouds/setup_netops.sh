#!/bin/sh

echo 'Netops...'

test -L /var/log/br/netops && echo 'Already installed!' && exit 0;

./setup_perl.sh || exit -1

# removed this ... not sure it's needed ...
#    ORBit2-2.14.17-3.2.el6_3

REQUIRED_PACKAGES="\
    ImageMagick-6.5.4.7-6.el6_2                 \
    GConf2-2.28.0-6.el6                         \
    libIDL-0.8.13-2.1.el6                       \
    libcroco-0.6.2-5.el6                        \
    libgsf-1.14.15-5.el6                        \
    librsvg2-2.26.0-5.el6_1.1.0.1.centos        \
    libtool-ltdl-2.2.6-15.5.el6                 \
    libwmf-lite-0.2.8.4-22.el6.centos           \
    sgml-common-0.6.3-32.el6                    \
    "
sudo yum install -y $REQUIRED_PACKAGES || exit -1

ln -s /home/br/gits/clouds/netops/log /var/log/br/netops

cat <<'EOT' >/tmp/br/clean_netops_logs
# .---------------- minute (0 - 59)
# |   .------------- hour (0 - 23)
# |   |   .---------- day of month (1 - 31)
# |   |   |   .------- month (1 - 12) OR jan,feb,mar,apr ...
# |   |   |   |  .----- day of week (0 - 7) (Sunday=0 or 7)  OR sun,mon,tue,wed,thu,fri,sat
# |   |   |   |  |
# *   *   *   *  *  user command to be executed
*     *   *   *  *  root find /home/br/gits/netops/log/* -mtime +7 -exec rm {} \;
EOT
sudo install -o root -m 644 /tmp/br/clean_netops_logs /etc/cron.d/clean_netops_logs

mkdir -p /home/br/tmp/files

exit 0

