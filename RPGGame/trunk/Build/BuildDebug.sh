#!/bin/sh
make clean
rm Src *Make* *make* -rf
cmake -DCMAKE_BUILD_TYPE=Debug ../
make
