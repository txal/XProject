cmake_minimum_required(VERSION 2.6)

aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}				src_logserver)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/DataStruct/Crypt src_crypt)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/TimerMgr  src_timermgr)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/LuaCommon src_luacommon)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/PacketParser src_packetparser)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/MGHttp 	src_mghttp)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Server/Base      src_base)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/LuaSupport 	src_luasupport)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/PacketProc		src_packetproc)

#set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Bin/_LocalServer/${CMAKE_BUILD_TYPE}/)
add_executable(LogServer
	${src_logserver}
	${src_base}
    ${src_timermgr}
	${src_luacommon}
	${src_luasupport}
	${src_packetproc}
	${src_packetparser}
	${src_mghttp}
	${src_crypt}
)

target_link_libraries(LogServer logger network dbdriver luawrapper)
target_link_libraries(LogServer lua530 mysqlclient jemalloc readline lpeg pbc cjson pthread rt)
