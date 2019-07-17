cmake_minimum_required(VERSION 2.6)

aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Server/Base          src_base)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}				    src_routerserver)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/PacketProc	        src_packetproc)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/LuaSupport         src_luasupport)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/PacketParser  src_packetparser)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/TimerMgr      src_timermgr)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/MGHttp 		src_mghttp)
aux_source_directory(${PROJECT_SOURCE_DIR}/../../Common/LuaCommon 	src_luacommon)


#set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Bin/_RouterServer/${CMAKE_BUILD_TYPE}/)
add_executable (RouterServer
	${src_base}
	${src_routerserver}
	${src_packetproc}
    ${src_luasupport}
    ${src_packetparser}
    ${src_timermgr}
    ${src_mghttp}
    ${src_luacommon}
)	

target_link_libraries(RouterServer logger network luawrapper dbdriver)
target_link_libraries(RouterServer lua530 mysqlclient readline pthread rt cjson lpeg pbc) #jemalloc 
