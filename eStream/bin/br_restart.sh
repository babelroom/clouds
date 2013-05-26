#!/bin/sh

if [ "$1" == '' ]
then
    echo "usage: br_restart 'command to restart'"
    exit -1
fi

while true
do
    $1
    sleep 1
done

exit 0

