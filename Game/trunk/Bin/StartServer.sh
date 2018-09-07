# /sbin/bash
rm debug.txt -f
ulimit -n 102400
ulimit -c unlimited
chmod 755 ./ -R

path=$PWD
${path}/RouterServer 11 &
ping 127.0.0.1 -c 2
${path}/GlobalServer 31 &
${path}/LogServer 41 &
${path}/LogicServer 51 &
${path}/GateServer 21 &
