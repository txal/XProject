# /sbin/bash

mkdir -m 755 -p DB/Center
mkdir -m 755 -p Log
chmod 755 ./ -R

path=$PWD
${path}/SSDBServer ./DB/center/ssdb.conf &
