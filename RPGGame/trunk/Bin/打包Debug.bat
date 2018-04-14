@echo off
rem TortoiseProc.exe /command:update /path:".\" /closeonend:3

set year=%date:~0,4% 
set month=%date:~5,2% 
set day=%date:~8,2% 

echo ´ò°üDebug°æ
del Server*.zip /Q
mkdir Game
xcopy /y/f .\Debug\*Server Game
7z a -tzip Server%year%%month%%day%.zip Game
rd /s/q Game

pause