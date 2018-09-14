cmake_minimum_required(VERSION 2.6)

aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Server/Base          src_base)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}				    src_routerserver)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/PacketProc	        src_packetproc)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/LuaSupport         src_luasupport)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/PacketParser  src_packetparser)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/TimerMgr      src_timermgr)

add_executable (RouterServer
	${src_base}
	${src_routerserver}
	${src_packetproc}
    ${src_luasupport}
    ${src_packetparser}
    ${src_timermgr}
)	

target_link_libraries(RouterServer logger network luawrapper)
target_link_libraries(RouterServer lua530 readline jemalloc pthread rt)
