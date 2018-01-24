@echo off
rem TortoiseProc.exe /command:update /path:".\" /closeonend:3

echo ´ò°üRelease
del Server.zip /Q
mkdir Game
xcopy /y/f .\Release\*Server Game
7z a -tzip Server.zip Game
rd /s/q Game

rem set target=E:\Game\Runtime\trunk\Server
rem xcopy /y/f Server.zip %target%
rem del Server.zip /Q

pause