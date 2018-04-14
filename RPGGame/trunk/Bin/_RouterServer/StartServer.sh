# /sbin/bash
# /sbin/bash
path=$PWD

ulimit -n 102400
ulimit -c unlimited

chmod 755 ./ -R
rm debug.txt -f

echo 启动路由服务器
${path}/RouterServer 1 &


