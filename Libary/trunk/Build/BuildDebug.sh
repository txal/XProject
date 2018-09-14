#!/bin/sh
make clean
rm *Make* *make* Source -rf 
cmake -DCMAKE_BUILD_TYPE=Debug ../
make
