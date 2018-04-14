pushd CenterDB
call StartDB.bat
popd

pushd _RouterServer
call StartServer.bat
popd

pushd _LocalServer
call StartServer.bat
popd

pushd _WorldServer
call StartServer.bat
popd
