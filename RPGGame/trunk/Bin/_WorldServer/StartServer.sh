# /sbin/bash
# /sbin/bash
path=$PWD

mkdir -m 755 -p DB/global
mkdir -m 755 -p DB/global2
mkdir -m 755 -p Log

ulimit -n 102400
ulimit -c unlimited

chmod 755 ./ -R
rm debug.txt -f

echo 重启世界SSDB
${path}/SSDBServer -d ./DB/global/ssdb.conf -s restart
${path}/SSDBServer -d ./DB/global2/ssdb.conf -s restart
ping 127.0.0.1 -c 4


echo 启动世界服务器
${path}/WGlobalServer 110 WGlobalServer &
${path}/WGlobalServer2 111 WGlobalServer2 &
ping 127.0.0.1 -c 1
${path}/LogicServer 100 &
ping 127.0.0.1 -c 1
${path}/LogicServer 101 &
ping 127.0.0.1 -c 1
${path}/LogicServer 102 &