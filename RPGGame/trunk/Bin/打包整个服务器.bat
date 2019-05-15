@echo off

set year=%date:~0,4% 
set month=%date:~5,2% 
set day=%date:~8,2% 
set name="mengzhu%year%%month%%day%"
set name="%name: =%"

set platform=Centos7

echo 删除旧包
del mengzhu*.zip /Q

mkdir %name%
xcopy /y/f .\*.sh %name%\

mkdir %name%\_LocalServer
xcopy /y/f .\_LocalServer\ServerConf.lua 	%name%\_LocalServer
xcopy /y/f .\_LocalServer\*sh 			%name%\_LocalServer
xcopy /y/f .\%platform%\GateServer  	%name%\_LocalServer
xcopy /y/f .\%platform%\LoginServer 	%name%\_LocalServer
xcopy /y/f .\%platform%\LogicServer 	%name%\_LocalServer
xcopy /y/f .\%platform%\LogServer		%name%\_LocalServer
xcopy /y/f .\%platform%\GlobalServer 	%name%\_LocalServer
xcopy /y/f .\%platform%\SSDBServer 	%name%\_LocalServer

mkdir %name%\_WorldServer
xcopy /y/f .\_WorldServer\ServerConf.lua 	%name%\_WorldServer
xcopy /y/f .\_WorldServer\*sh 			%name%\_WorldServer
xcopy /y/f .\%platform%\RouterServer	%name%\_WorldServer
xcopy /y/f .\%platform%\WGlobalServer 	%name%\_WorldServer
xcopy /y/f .\%platform%\LogicServer 	%name%\_WorldServer
xcopy /y/f .\%platform%\SSDBServer 	%name%\_WorldServer

mkdir %name%\CenterDB
xcopy /y/f .\CenterDB\*sh 			%name%\CenterDB
xcopy /y/f .\%platform%\SSDBServer 	%name%\CenterDB

mkdir %name%\_RobotClient
xcopy /y/f .\%platform%\RobotClt %name%\_RobotClient
xcopy /y/f .\_RobotClient\*.lua %name%\_RobotClient


echo 打包数据库配置
mkdir %name%\CenterDB\DB\center
xcopy /y/f CenterDB\DB\center\ssdb.conf %name%\CenterDB\DB\center

mkdir %name%\_LocalServer\DB\user
xcopy /y/f _LocalServer\DB\user\ssdb.conf %name%\_LocalServer\DB\user

mkdir %name%\_WorldServer\DB\global
xcopy /y/f _WorldServer\DB\global\ssdb.conf %name%\_WorldServer\DB\global


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

7z a -tzip %name%.zip %name%\*
rd /s/q %name%
pause