# /sbin/bash

mkdir -m 755 -p DB/user
mkdir -m 755 -p DB/center
mkdir -m 755 -p Log
chmod 755 ./ -R

path=$PWD
${path}/../SSDBServer ./DB/user/ssdb.conf &
${path}/../SSDBServer ./DB/global/ssdb.conf &
