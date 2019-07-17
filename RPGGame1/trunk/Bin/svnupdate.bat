@echo off

echo 更新======
pushd ..\..\Data
TortoiseProc.exe /command:update /path:".\" /closeonend:3
popd

pushd ..\..\Server
TortoiseProc.exe /command:update /path:".\" /closeonend:3
popd

rem echo 导表======
rem pushd ..\..\Data\Tools\ExportTable\Server
rem call Xls2Lua.bat
rem popd

echo 协议======
pushd ..\..\Data\Protobuf
..\Tools\PHP\php.exe ServerPBList.php
popd


