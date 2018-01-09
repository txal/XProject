cmake_minimum_required(VERSION 2.6)

aux_source_directory(src src_pbc)
aux_source_directory(binding/lua53 src_pbc_binding)
include_directories(.)

set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Libs/Linux64/${CMAKE_BUILD_TYPE}/3rd)

add_library(pbc STATIC ${src_pbc} ${src_pbc_binding})
set_target_properties(pbc PROPERTIES output_name "pbc")
