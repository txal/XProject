cmake_minimum_required(VERSION 2.6)

aux_source_directory(. src_lpeg)

set(LIBRARY_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Libs/Linux64/${CMAKE_BUILD_TYPE}/3rd)

add_library(lpeg STATIC ${src_lpeg})
set_target_properties(lpeg PROPERTIES output_name "lpeg")
