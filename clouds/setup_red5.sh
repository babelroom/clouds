#!/bin/sh

echo 'Red5...'

test -d red5 && echo "Red5 already exists" && exit 0

REQUIRED_PACKAGES="\
    java-1.6.0-openjdk-1.6.0.0-1.45.1.11.1.el6      \
    flac-1.2.1-6.1.el6                              \
    giflib-4.1.6-3.1.el6                            \
    jline-0.9.94-0.8.el6                            \
    jpackage-utils-1.7.5-3.12.el6                   \
    libasyncns-0.8-1.1.el6                          \
    libsndfile-1.0.20-5.el6                         \
    pulseaudio-libs-0.9.21-14.el6_3                 \
    rhino-1.7-0.7.r2.2.el6                          \
    tzdata-java-2012i-2.el6                         \
    "
sudo yum install -y $REQUIRED_PACKAGES || exit -1

SAVE=$PWD
cd $HOME/gits

git clone http://github.com/babelroom/red5.git || exit -1

test -L /var/log/br/red5 || ln -s /home/br/gits/red5/red5-1.0.0/log /var/log/br/red5

cd $SAVE

exit 0

