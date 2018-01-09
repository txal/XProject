cmake_minimum_required(VERSION 2.6)

#include_directories(/usr/include/mysql)

aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/Mysql 	src_mysqldriver)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/SSDB 	src_ssdbdriver)

add_library(dbdriver STATIC ${src_ssdbdriver} ${src_mysqldriver})
set_target_properties(dbdriver PROPERTIES output_name "dbdriver")

