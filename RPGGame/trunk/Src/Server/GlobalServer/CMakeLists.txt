cmake_minimum_required(VERSION 2.6)

aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Server/Base          src_base)
aux_source_directory(${PROJECT_SOURCE_DIR}/../..//Common/TimerMgr      src_timermgr)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/WordFilter    src_wordfilter)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/LuaCommon     src_luacommon)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/MGHttp        src_mghttp)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/WordFilter 	src_wordfilter)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/PacketParser src_packetparser)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}                    src_globalserver)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/LuaSupport         src_luasupport)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/PacketProc 		src_packetproc)

#set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Bin/_LocalServer/${CMAKE_BUILD_TYPE}/)
add_executable(GlobalServer
    ${src_base}
    ${src_timermgr}
    ${src_wordfilter}
    ${src_luacommon}
    ${src_wordfilter}
	${src_globalserver}
	${src_luasupport}
	${src_packetproc}
    ${src_mghttp}
    ${src_packetparser}
)

target_link_libraries(GlobalServer logger network dbdriver luawrapper)
target_link_libraries(GlobalServer lua530 ssdb-client mysqlclient jemalloc readline lpeg pbc pthread rt cjson)
#如果需要ssl
#yum install zlib-devel
#yum install openssl-devel
