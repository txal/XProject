#!/bin/sh
make clean
cmake -DCMAKE_BUILD_TYPE=Debug ../
make
