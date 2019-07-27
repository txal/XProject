cmake_minimum_required(VERSION 2.6)

aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Server/Base          src_base)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}                    src_gateserver)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/PacketProc         src_packetproc)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/ClientMgr          src_clientmgr)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/PacketParser src_packetparser)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/LuaCommon     src_luacommon)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/TimerMgr      src_timermgr)

#set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Bin/_LocalServer/${CMAKE_BUILD_TYPE}/)
add_executable(GateServer
	${src_base}
	${src_gateserver}
	${src_packetproc}
	${src_clientmgr}
	${src_packetparser}
	${src_timermgr}
	${src_luacommon}
)

target_link_libraries(GateServer logger network luawrapper dbdriver)
target_link_libraries(GateServer lua530 mysqlclient jemalloc readline pthread rt)
