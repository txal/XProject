# /sbin/bash
path=$PWD

mkdir -m 755 -p DB/user
mkdir -m 755 -p Log

ulimit -n 10240
ulimit -c unlimited

chmod 755 ./ -R
rm debug.txt -f
rm adb.txt -f

echo 重启本地SSDB
./StartDB.sh
ping 127.0.0.1 -c 4


echo 启动本地服务器
${path}/LogServer 30 &
ping 127.0.0.1 -c 1
${path}/GlobalServer 20 &
ping 127.0.0.1 -c 1
${path}/LogicServer 50 &
ping 127.0.0.1 -c 1
${path}/LoginServer 40 &
ping 127.0.0.1 -c 1
${path}/GateServer 10 &
