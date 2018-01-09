cmake_minimum_required(VERSION 2.6)

aux_source_directory(src src_lua)
set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Libs/Linux64/${CMAKE_BUILD_TYPE}/3rd)

add_library(lua530 STATIC ${src_lua})
set_target_properties(lua530 PROPERTIES output_name "lua530")
