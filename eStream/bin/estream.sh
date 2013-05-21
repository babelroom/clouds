#!/bin/sh 

export BIN_DIR=/usr/local/estream/bin
export LD_LIBRARY_PATH=.:$LD_LIBRARY_PATH
ulimit -c unlimited
cd ${BIN_DIR} && ./br_restart.sh './estream ../conf/WebServ.conf' 2>/var/log/br/estream_sh.log &
sleep 2

# but this looks cleaner under ps
# ALSO there is an scp cmd at the bottom of FS_in.pl (spawned by FS_out.pl)(well, maybe not anymore)
# which needs to run as root in the current system configuration
cd ${BIN_DIR} && ./FS_out.pl 2>/var/log/br/FS_out_err.log &

# this is necessary both to create the q, but more importantly to make sure 
# commands (such as originate) are not re-issued on restarting estream
cd ${BIN_DIR} && ./br_restart.sh './FS_in.pl _' 2>/var/log/br/FS_in_err.log &

