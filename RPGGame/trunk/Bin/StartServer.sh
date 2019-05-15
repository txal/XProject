# /sbin/bash

#pushd CenterDB
#chmod 755 *.sh
#./StartDB.sh
#popd

pushd _WorldServer
chmod 755 *.sh
./StartServer.sh
popd


pushd _LocalServer
chmod 755 *.sh
./StartServer.sh
popd

pushd _LocalServer2
chmod 755 *.sh
./StartServer.sh
popd
