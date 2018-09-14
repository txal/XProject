@echo off
rem TortoiseProc.exe /command:update /path:".\" /closeonend:3

set year=%date:~0,4% 
set month=%date:~5,2% 
set day=%date:~8,2% 
set name="mengzhu%year%%month%%day%"
set name="%name: =%"

set 
echo ´ò°üRelease°æ
del mengzhu*.zip /Q

mkdir Game
xcopy /y/f .\*.sh Game\

mkdir Game\_LocalServer
xcopy /y/f .\Release\GateServer Game\_LocalServer
xcopy /y/f .\Release\LoginServer Game\_LocalServer
xcopy /y/f .\Release\LogicServer Game\_LocalServer
xcopy /y/f .\Release\LogServer Game\_LocalServer
xcopy /y/f .\Release\GlobalServer Game\_LocalServer
xcopy /y/f .\Release\SSDBServer Game\_LocalServer
xcopy /y/f .\_LocalServer\*sh Game\_LocalServer

mkdir Game\_RouterServer
xcopy /y/f .\Release\RouterServer Game\_RouterServer
xcopy /y/f .\_RouterServer\*sh Game\_RouterServer

mkdir Game\_WorldServer
xcopy /y/f .\Release\WGlobalServer Game\_WorldServer
echo f | xcopy /y/f .\Release\WGlobalServer Game\_WorldServer\WGlobalServer2
xcopy /y/f .\Release\LogicServer Game\_WorldServer
xcopy /y/f .\Release\SSDBServer Game\_WorldServer
xcopy /y/f .\_WorldServer\*sh Game\_WorldServer

mkdir Game\_CenterDB
xcopy /y/f .\Release\SSDBServer Game\_CenterDB
xcopy /y/f .\CenterDB\*sh Game\_CenterDB

mkdir Game\_RobotClient
xcopy /y/f .\Release\RobotClt Game\_RobotClient

7z a -tzip %name%.zip Game
rd /s/q Game

pause