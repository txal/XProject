cmake_minimum_required(VERSION 2.6)

aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR} src_logger)

add_library(logger STATIC ${src_logger})
set_target_properties(logger PROPERTIES output_name "logger")

