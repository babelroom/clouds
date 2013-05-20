#!/bin/sh

echo 'FreeSWITCH...'

test -x /usr/local/bin/freeswitch && echo 'Already installed!' && exit 0;

./setup_buildtools.sh || exit -1
./setup_fail2ban.sh || exit -1

REQUIRED_PACKAGES="\
    autoconf-2.63-5.1.el6                       \
    automake-1.11.1-1.2.el6                     \
    libtool-2.2.6-15.5.el6                      \
    ncurses-devel-5.7-3.20090208.el6            \
    libjpeg-devel-6b-46.el6                     \
    zlib-devel-1.2.3-27.el6                     \
    "
sudo yum install -y $REQUIRED_PACKAGES || exit -1

SAVE=$PWD

# download sound files
cd $HOME
test -d src/sounds || mkdir -p src/sounds
cd src/sounds  || exit -1
test -f freeswitch-sounds-en-us-callie-8000-1.0.22.tar.gz || wget http://files.freeswitch.org/freeswitch-sounds-en-us-callie-8000-1.0.22.tar.gz
test -f freeswitch-sounds-en-us-callie-16000-1.0.22.tar.gz || wget http://files.freeswitch.org/freeswitch-sounds-en-us-callie-16000-1.0.22.tar.gz
test -f freeswitch-sounds-music-8000-1.0.8.tar.gz || wget http://files.freeswitch.org/freeswitch-sounds-music-8000-1.0.8.tar.gz
test -f freeswitch-sounds-music-16000-1.0.8.tar.gz || wget http://files.freeswitch.org/freeswitch-sounds-music-16000-1.0.8.tar.gz

# build freeswitch
cd $HOME/gits

test -d FS && echo "FS directory already exists -- cleanup (rm -rf FS) then restart" && exit -1

# get files to build
git clone http://github.com/babelroom/FS.git || exit -1
cd FS
git clone -b v1.2.stable git://git.freeswitch.org/freeswitch.git

cd freeswitch
git checkout 38e3f5fe1655336f9fc807e62f877ed8f932b8a0   # get back to source as of 08/08/2011 (TMP TODO)
cp -a ../cs_src_overlay/* .
./bootstrap.sh
./configure --without-pgsql
make
sudo make install
sudo cp -a ../cs_overlay/* /usr/local/freeswitch
sudo rm /usr/local/freeswitch/README
#sudo install -o root -m 755 build/freeswitch.init.redhat /etc/init.d/freeswitch # --- in the future
sudo install -o root -m 755 ../freeswitch.rc /etc/init.d/freeswitch

echo "Copying freeswitch sounds..."
cd $HOME/src/sounds
for FILE in *.gz
do
    gzip -cd $FILE | tar xvf -
done
sudo cp -a en music /usr/local/freeswitch/sounds
sudo chown -R root:root /usr/local/freeswitch/sounds
cd ..
rm -rf sounds

echo "Conference recordings base setup..."
sudo mkdir -p /cs_media/conf_recordings
cat <<'EOT' >/tmp/br/xfercron
# .---------------- minute (0 - 59)
# |   .------------- hour (0 - 23)
# |   |   .---------- day of month (1 - 31)
# |   |   |   .------- month (1 - 12) OR jan,feb,mar,apr ...
# |   |   |   |  .----- day of week (0 - 7) (Sunday=0 or 7)  OR sun,mon,tue,wed,thu,fri,sat
# |   |   |   |  |
# *   *   *   *  *  user command to be executed
*     *   *   *  *  root /usr/local/freeswitch/scripts/xfercron.sh
EOT
sudo install -o root -m 644 /tmp/br/xfercron /etc/cron.d/xfercron

cd $SAVE

REQUIRED_PACKAGES="\
    screen-4.0.3-16.el6                         \
    "
sudo yum install -y $REQUIRED_PACKAGES || exit -1

exit 0

