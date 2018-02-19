@echo off



echo 生成客户端表======
rem pushd Client

rem call Xls2Js.bat

rem popd



echo 生成服务端表======
pushd Server

call Xls2Lua.bat

popd
