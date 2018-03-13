pushd _RouterServer
call StartRouterServer.bat
popd

pushd _WorldServer
call StartServer.bat
popd

pushd _LocalServer
call StartServer.bat

