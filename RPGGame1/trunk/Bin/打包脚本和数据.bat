@echo off

set year=%date:~0,4% 
set month=%date:~5,2% 
set day=%date:~8,2% 
set name="mengzhu%year%%month%%day%"
set name="%name: =%"

echo 删除旧包
del mengzhu*.zip /Q


echo 打包服务器脚本
mkdir %name%\Script
xcopy /y/f/e Script %name%\Script

echo 打包数据文件
mkdir %name%\Data\Config\CSV\
xcopy /y/f/e ..\Data\Config\CSV %name%\Data\Config\CSV

mkdir %name%\Data\Protobuf
xcopy /y/f/e ..\Data\Protobuf %name%\Data\Protobuf

mkdir %name%\Data\ServerMap
xcopy /y/f/e ..\Data\ServerMap %name%\Data\ServerMap

7z a -tzip %name%.zip %name%
rd /s/q %name%