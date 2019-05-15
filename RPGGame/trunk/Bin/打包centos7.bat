@echo off

set year=%date:~0,4% 
set month=%date:~5,2% 
set day=%date:~8,2% 
set name="centos7-%year%%month%%day%"
set name="%name: =%"

echo 删除旧包
del centos7*.zip /Q


echo 打包服务器脚本
mkdir %name%
xcopy /y/f/e Centos7\* %name%\

7z a -tzip %name%.zip %name%
rd /s/q %name%