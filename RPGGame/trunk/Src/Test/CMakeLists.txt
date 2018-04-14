cmake_minimum_required(VERSION 2.6)

aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}                    src_test)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/HttpRequest   src_httprequest)

add_executable (Test 
    ${src_test}
    ${src_httprequest}
)   

target_link_libraries(Test logger curl pthread rt z ssl crypto)
