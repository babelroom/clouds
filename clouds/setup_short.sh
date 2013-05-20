#!/bin/sh

./setup_nginx.sh || exit -1;
./setup_estream_bin.sh || exit -1;
./setup_mysqld.sh || exit -1;
./setup_node.sh || exit -1;
./setup_gen.sh || exit -1;

exit 0;

