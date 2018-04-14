# /sbin/bash

pushd CenterDB
./StartDB.sh
popd

pushd _RouterServer
./StartServer.sh
popd

pushd _LocalServer
./StartServer.sh
popd

pushd _WorldServer
./StartServer.sh
popd
