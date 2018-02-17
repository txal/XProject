@echo off

echo 生成客户端协议======
rem ..\Tools\PHP\php.exe ClientPbList.php
rem xcopy *.js ..\..\Client\assets\scripts\protobuf\ /y/f
rem del *.js

echo 生成服务器协议======
..\Tools\PHP\php.exe ServerPbList.php
rem pause()