@echo off

TortoiseProc.exe /command:update /path:".\" /closeonend:3

call 协议.bat
call 导表.bat

