cmake_minimum_required(VERSION 2.6)

aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Server/Base          src_base)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/Filter 		src_filter)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/TimerMgr      src_timermgr)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/LuaCommon     src_luacommon)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/PacketParser  src_packetparser)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/CSVDocument 	src_csvdocument)
aux_source_directory(${PROJECT_SOURCE_DIR}/Src/Common/WordFilter 	src_wordfilter)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}				    src_logicserver)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/LuaSupport         src_luasupport)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/PacketProc         src_packetproc)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/SceneMgr           src_scenemgr)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/Object             src_object)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/Object/Role      	src_object_role)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/Object/Monster     src_object_monster)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/Object/DropItem    src_object_dropitem)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/Object/Robot 		src_object_robot)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/ConfMgr            src_confmgr)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/Component/AStar 	src_astar)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/Component/Buff 	src_buff)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/Component/AI 		src_ai)

#set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/Bin/_LocalServer/${CMAKE_BUILD_TYPE}/)
add_executable(LogicServer
    ${src_base}
    ${src_filter}
    ${src_timermgr}
    ${src_luacommon}
    ${src_packetparser}
    ${src_csvdocument}
	${src_logicserver}
	${src_luasupport}
	${src_packetproc}
	${src_scenemgr} 
	${src_object} 
	${src_object_role} 
	${src_object_monster} 
	${src_object_dropitem} 
	${src_object_robot}
	${src_confmgr} 
	${src_astar}
	${src_buff}
	${src_ai}
	${src_wordfilter}
)

target_link_libraries(LogicServer logger network dbdriver luawrapper)
target_link_libraries(LogicServer lua530 mysqlclient ssdb-client readline lpeg pbc pthread rt cjson) #jemalloc 
