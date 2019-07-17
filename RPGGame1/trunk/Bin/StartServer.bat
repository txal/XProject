rem pushd CenterDB
rem call StartDB.bat
rem popd

pushd _WorldServer
call StartServer.bat
popd

pushd _LocalServer
call StartServer.bat
popd
