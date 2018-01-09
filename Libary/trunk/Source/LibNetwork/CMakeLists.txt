cmake_minimum_required(VERSION 2.6)

aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}    	src_network)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/Ae 	src_ae)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/MailBox src_mailbox)
aux_source_directory(${CMAKE_CURRENT_SOURCE_DIR}/NetUtil src_netutil)

add_library(network STATIC	${src_network} ${src_ae} ${src_mailbox} ${src_netutil})
set_target_properties(network PROPERTIES output_name "network")
