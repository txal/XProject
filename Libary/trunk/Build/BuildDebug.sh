#!/bin/sh
rm *Make* *make* Source -rf
make clean
cmake -DCMAKE_BUILD_TYPE=Debug ../
make
