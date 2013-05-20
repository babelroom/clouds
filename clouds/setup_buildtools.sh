#!/bin/sh

echo 'checking for gcc build tools...'

# these versions are explicit just to lock in specifics
which g++ 2>/dev/null || sudo yum -y install gcc-4.4.6-4.el6 cloog-ppl-0.15.7-1.2.el6 cpp-4.4.6-4.el6 glibc-devel-2.12-1.80.el6_3.6 glibc-headers-2.12-1.80.el6_3.6 kernel-headers-2.6.32-279.14.1.el6 mpfr-2.4.1-6.el6 ppl-0.10.2-11.el6 glibc-2.12-1.80.el6_3.6 glibc-common-2.12-1.80.el6_3.6 gcc-c++-4.4.6-4.el6 libstdc++-devel-4.4.6-4.el6 || exit -1

exit 0

