cmake_minimum_required(VERSION 2.6)
project(XProject)

set(CMAKE_CXX_FLAGS_DEBUG "$ENV{CXXFLAGS} -std=c++0x -O0 -Wall -g -ggdb -D_DEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "$ENV{CXXFLAGS} -std=c++0x -g -O2 -Wall")

link_directories(${PROJECT_SOURCE_DIR}/Libs/Linux64/${CMAKE_BUILD_TYPE}/)
link_directories(${PROJECT_SOURCE_DIR}/Libs/Linux64/${CMAKE_BUILD_TYPE}/3rd)
#link_directories(./)

link_directories(/usr/lib64/mysql/)
link_directories(/usr/lib64/)


include_directories(${PROJECT_SOURCE_DIR}/Src)
set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Bin)

add_subdirectory(Src)
