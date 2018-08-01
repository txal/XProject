@echo off
rem TortoiseProc.exe /command:update /path:".\" /closeonend:3

set year=%date:~0,4% 
set month=%date:~5,2% 
set day=%date:~8,2% 
set name="mengzhu%year%%month%%day%"
set name="%name: =%"

echo ´ò°üDebug°æ
del Server*.zip /Q

mkdir Game
xcopy /y/f .\*.sh Game\

mkdir Game\_LocalServer
xcopy /y/f .\_LocalServer\*Server Game\_LocalServer
xcopy /y/f .\_LocalServer\*sh Game\_LocalServer

mkdir Game\_RouterServer
xcopy /y/f .\_RouterServer\*Server Game\_RouterServer
xcopy /y/f .\_RouterServer\*sh Game\_RouterServer

mkdir Game\_WorldServer
xcopy /y/f .\_WorldServer\*Server* Game\_WorldServer
xcopy /y/f .\_WorldServer\*sh Game\_WorldServer

mkdir Game\_CenterDB
xcopy /y/f .\CenterDB\*Server Game\_CenterDB
xcopy /y/f .\CenterDB\*sh Game\_CenterDB

mkdir Game\_RobotClient
xcopy /y/f .\_RobotClient\RobotClt Game\_RobotClient

7z a -tzip %name%.zip Game
rd /s/q Game

pause