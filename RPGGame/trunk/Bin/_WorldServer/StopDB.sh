# /sbin/bash

path=$PWD

${path}/SSDBServer -d ./DB/global/ssdb.conf -s stop
${path}/SSDBServer -d ./DB/global2/ssdb.conf -s stop
