@echo off
rem TortoiseProc.exe /command:update /path:".\" /closeonend:3

echo 打包拷贝到开发环境
del Server.zip /Q
mkdir Game
xcopy /y/f *Server Game
7z a -tzip Server.zip Game
rd /s/q Game

rem set target=E:\Game\Runtime\trunk\Server
rem xcopy /y/f Server.zip %target%
rem del Server.zip /Q

pause