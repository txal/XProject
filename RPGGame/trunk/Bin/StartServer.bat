pushd _RouterServer
call StartRouterServer.bat
popd

pushd _WorldServer
call StartDB.bat
call StartGlobalServer.bat
call StartLogicServer.bat
popd

pushd _LocalServer
call StartDB.bat
call StartLogServer.bat
call StartLoginServer.bat
call StartGlobalServer.bat
call StartLogicServer.bat
call StartGateServer.bat
