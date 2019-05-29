cmake_minimum_required(VERSION 2.6)
project(Libary)

set(CMAKE_CXX_FLAGS_DEBUG "$ENV{CXXFLAGS} -std=c++0x -O0 -Wall -g -ggdb -D_DEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "$ENV{CXXFLAGS} -std=c++0x -g -O2 -Wall -DNDEBUG")

include_directories(${PROJECT_SOURCE_DIR}/Source)
include_directories(${PROJECT_SOURCE_DIR}/../../RPGGame/trunk/Src)

set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Libs/Linux64/${CMAKE_BUILD_TYPE})

add_subdirectory(Source)
