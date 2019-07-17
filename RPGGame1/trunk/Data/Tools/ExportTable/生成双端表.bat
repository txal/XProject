@echo off



echo 生成客户端表======
pushd Client
call Xls2Js.bat
popd



echo 生成服务端表======
pushd Server
call Xls2Lua.bat
popd
