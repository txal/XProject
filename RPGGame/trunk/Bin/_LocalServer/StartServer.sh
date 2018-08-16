# /sbin/bash
path=$PWD

mkdir -m 755 -p DB/global
mkdir -m 755 -p DB/user
mkdir -m 755 -p Log

ulimit -n 102400
ulimit -c unlimited

chmod 755 ./ -R
rm debug.txt -f

echo 重启本地SSDB
${path}/SSDBServer -d ./DB/user/ssdb.conf -s restart
${path}/SSDBServer -d ./DB/global/ssdb.conf -s restart


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
