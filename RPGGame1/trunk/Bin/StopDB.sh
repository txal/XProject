# /sbin/bash

path=$PWD

pushd _LocalServer
./StopDB.sh
popd

pushd _WorldServer
./StopDB.sh
popd

