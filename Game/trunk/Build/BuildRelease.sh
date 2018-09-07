#!/bin/sh
make clean
cmake -DCMAKE_BUILD_TYPE=Release ../
make
