# /sbin/bash

mkdir -m 755 -p DB/global
mkdir -m 755 -p Log
chmod 755 ./ -R

path=$PWD
${path}/SSDBServer -d ./DB/global/ssdb.conf -s restart
#${path}/SSDBServer -d ./DB/global2/ssdb.conf -s restart
