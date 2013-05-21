#!/bin/sh

echo 'Perl...'

./setup_buildtools.sh || exit -1

SAVE=$PWD
cd $HOME/gits/clouds/clouds

perl ../br_scripts/check_for_modules.pl 2>/dev/null && echo 'Already installed!' && exit 0;

REQUIRED_PACKAGES="\
    perl-CPAN-1.9402-127.el6                    \
    perl-Digest-SHA-5.47-127.el6                \
    perl-Module-Build-0.3500-127.el6            \
    perl-Archive-Tar-1.58-127.el6               \
    perl-ExtUtils-CBuilder-0.27-127.el6         \
    perl-IO-Zlib-1.09-127.el6                   \
    perl-Package-Constants-0.02-127.el6         \
    perl-ExtUtils-MakeMaker-6.55-127.el6        \
    perl-ExtUtils-ParseXS-1:2.2003.0-127.el6    \
    perl-Test-Harness-3.17-127.el6              \
    perl-devel-4:5.10.1-127.el6                 \
    "
sudo yum install -y $REQUIRED_PACKAGES || exit -1
# an method which restricts the repo used so we only get the base (correct) version rather than all the jazz with the explicit packages and version numbers
#sudo yum install --disablerepo=\* --enablerepo=C6.3-base -y $REQUIRED_PACKAGES || exit -1

mkdir -p ~/.cpan/CPAN
cp ./MyConfig.pm ~/.cpan/CPAN/ || exit -1

# modules, in order of dependency (important)
PERL_MODULES=(
MSTROUT/YAML-0.84
RJBS/Email-Date-Format-1.002
RJBS/Email-Simple-2.100
RJBS/Return-Value-1.666001
RJBS/Email-Address-1.892
RJBS/Email-Send-2.198
NANIS/Crypt-SSLeay-0.58
MCRAWFOR/REST-Client-171
STEVE/String-Random-0.22 
MJD/Text-Template-1.45
KASEI/Class-Accessor-0.34
GAAS/Digest-SHA1-2.13
GAAS/Digest-HMAC-1.02
DMUEY/Digest-MD5-File-0.07
JESSE/LWP-UserAgent-Determined-1.05
PERIGRIN/XML-NamespaceSupport-1.11
GRANTM/XML-SAX-0.96
BJOERN/XML-SAX-Expat-0.40
GRANTM/XML-Simple-2.18
TIMA/Amazon-S3-0.45
GBARR/Authen-SASL-2.15
FLORA/Net-SSLeay-1.36
SULLR/IO-Socket-SSL-1.43
CWEST/Net-SMTP-SSL-1.01
LBROCARD/Email-Send-Gmail-0.33
)

for item in ${PERL_MODULES[*]}
do
    PERL_MM_USE_DEFAULT=1 cpan -i ${item}.tar.gz 
done

# determine if it all worked out ...
perl ../br_scripts/check_for_modules.pl || exit -1

cd $SAVE

exit 0

