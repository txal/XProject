@echo off

..\..\PHP\php.exe ../XML2Lua.php ../../../Config ../../../../Server/Script/Config
..\..\PHP\php.exe ../CSV2Lua.php ../../../Config ../../../../Server/Script/Config

set pwd=%~dp0
set lua=%pwd%..\..\LUA\
pushd ..\..\..\..\Server\Script\
"%lua%\lua530.exe" -e "require(\"Common\\ConfCheck\\ToolConfCheck\")"
popd

rem pause