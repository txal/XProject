# /sbin/bash
# /sbin/bash
path=$PWD

mkdir -m 755 -p DB/global
mkdir -m 755 -p Log

ulimit -n 10240
ulimit -c unlimited

chmod 755 ./ -R
rm debug.txt -f
rm adb.txt -f

echo 重启世界SSDB
./StartDB.sh
ping 127.0.0.1 -c 3

echo 启动路由服务器
${path}/RouterServer 1 &
ping 127.0.0.1 -c 3

echo 启动世界服务器
${path}/WGlobalServer 110 WGlobalServer &
${path}/WGlobalServer 111 WGlobalServer2 &
ping 127.0.0.1 -c 1
${path}/LogicServer 100 &
ping 127.0.0.1 -c 1
${path}/LogicServer 101 &
ping 127.0.0.1 -c 1
${path}/LogicServer 102 &