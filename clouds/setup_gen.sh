#!/bin/sh

echo 'gen...'

./setup_node.sh || exit -1; # need node for npm in order to install uglifyjs

SAVE=$PWD
cd $HOME/gits/clouds/gen

git pull || exit -1

# install uglifyjs 
test -x /usr/local/bin/uglifyjs || sudo /usr/local/bin/npm -g install uglify-js 

make 

cd $SAVE

exit 0

