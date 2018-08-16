cmake_minimum_required(VERSION 2.6)

aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}				src_loginserver)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/TimerMgr  src_timermgr)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/LuaCommon src_luacommon)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/PacketParser src_packetparser)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Server/Base      src_base)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/LuaSupport 	src_luasupport)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/PacketProc		src_packetproc)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/WordFilter 	src_wordfilter)

#set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Bin/_LocalServer)
add_executable(LoginServer
	${src_loginserver}
	${src_base}
    ${src_timermgr}
	${src_luacommon}
	${src_luasupport}
	${src_packetproc}
	${src_wordfilter}
	${src_packetparser}
)

target_link_libraries(LoginServer logger network dbdriver luawrapper)
target_link_libraries(LoginServer lua530 ssdb-client mysqlclient readline lpeg pbc jemalloc pthread rt cjson)
