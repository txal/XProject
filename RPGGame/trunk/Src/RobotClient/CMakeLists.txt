cmake_minimum_required(VERSION 2.6)

aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Server/Base          src_base)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/Filter      	src_filter)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/TimerMgr      src_timermgr)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/LuaCommon     src_luacommon)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/PacketParser  src_packetparser)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/CSVDocument 	src_csvdocument)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/WordFilter    src_wordfilter)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}                    src_robotclient)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/LuaSupport         src_luasupport)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/PacketProc         src_packetproc)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Server/LogicServer/ConfMgr  src_confmgr)

set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Bin/_RobotClient/${CMAKE_BUILD_TYPE}/)
add_executable(RobotClt
    ${src_base}
    ${src_filter}
    ${src_timermgr}
    ${src_luasupport}
    ${src_luacommon}
    ${src_packetproc}
    ${src_csvdocument}
    ${src_packetparser}
    ${src_robotclient}
    ${src_confmgr}
    ${src_wordfilter}
)

target_link_libraries(RobotClt logger network dbdriver luawrapper)
target_link_libraries(RobotClt ssdb-client lua530 readline lpeg pbc cjson jemalloc pthread rt) 
