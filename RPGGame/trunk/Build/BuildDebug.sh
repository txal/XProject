#!/bin/sh
make clean
cmake -DCMAKE_BUILD_TYPE=Debug ../
make

cp ../Bin/_LocalServer/LogicServer ../Bin/_WorldServer/
cp ../Bin/_WorldServer/WGlobalServer ../Bin/_WorldServer/WGlobalServer2
