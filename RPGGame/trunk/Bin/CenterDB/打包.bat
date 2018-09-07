@echo off

echo 删除旧包
del globaldb.zip /Q

echo 打包全局数据库
mkdir globaldb\
xcopy /y/f *.sh globaldb\
xcopy /y/f SSDBServer globaldb\

echo 打包数据库结构
mkdir globaldb\DB\Center
xcopy /y/f DB\Center\ssdb.conf globaldb\DB\Center


7z a -tzip GlobalDB.zip globaldb
rd /s/q globaldb
pause

