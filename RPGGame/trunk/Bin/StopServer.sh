# /sbin/bash

path=$PWD

pushd _LocalServer
./StopServer.sh
popd

pushd _WorldServer
./StopServer.sh
popd

pushd _RouterServer
./StopServer.sh
popd
