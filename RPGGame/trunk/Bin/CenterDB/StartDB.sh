# /sbin/bash

mkdir -m 755 -p DB/center
mkdir -m 755 -p Log
chmod 755 ./ -R

path=$PWD
${path}/SSDBServer -d ./DB/center/ssdb.conf -s restart
