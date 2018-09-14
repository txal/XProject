# /sbin/bash

mkdir -m 755 -p DB/Player
mkdir -m 755 -p Log
chmod 755 ./ -R

path=$PWD
${path}/SSDBServer ./DB/Player/ssdb.conf &
