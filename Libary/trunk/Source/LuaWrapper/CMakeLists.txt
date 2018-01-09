cmake_minimum_required(VERSION 2.6)

aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR} src_luawrapper)

add_library(luawrapper STATIC ${src_luawrapper})
set_target_properties(luawrapper PROPERTIES output_name "luawrapper")

