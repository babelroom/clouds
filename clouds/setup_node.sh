#!/bin/sh

echo 'node...'

# not sure this check is valid, node is also installed just so uglify is available
which node 2>/dev/null && echo 'Already installed!' && exit 0;

./setup_buildtools.sh || exit -1

cd $HOME
test -d src || mkdir src
cd src  || exit -1

# node src
test -f ./node-v0.8.14.tar.gz || wget http://nodejs.org/dist/v0.8.14/node-v0.8.14.tar.gz || exit -1
gzip -cd node-v0.8.14.tar.gz | tar xvf - 
cd node-v0.8.14
./configure
make
sudo make install

# BR src (via gen)
cd $HOME/gits/clouds/clouds || exit -1
./setup_gen.sh || exit -1

# copy index.html (landing page for single IP deploy)
cp /home/br/gits/clouds/clouds/misc/index.html ~/.

# make directory for file uploads
mkdir /home/br/tmp/upl

exit 0

