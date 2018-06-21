#!/bin/sh
make clean
cmake -DCMAKE_BUILD_TYPE=Release ../
make

echo ****** copy 'LogicServer' to _WorldServer/ ******
cp ../Bin/_LocalServer/LogicServer ../Bin/_WorldServer/
