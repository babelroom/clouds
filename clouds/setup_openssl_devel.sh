#!/bin/sh

echo 'OpenSSL devel...'

REQUIRED_PACKAGES="\
    openssl-1.0.0-25.el6_3.1                    \
    krb5-libs-1.9-33.el6_3.3                    \
    zlib-devel-1.2.3-27.el6                     \
    libsepol-devel-2.0.41-4.el6                 \
    libselinux-devel-2.0.94-5.3.el6             \
    libcom_err-devel-1.41.12-12.el6             \
    keyutils-libs-devel-1.4-4.el6               \
    openssl-devel-1.0.0-25.el6_3.1              \
    krb5-devel-1.9-33.el6_3.3                   \
    "
sudo yum install -y $REQUIRED_PACKAGES || exit -1

exit 0

