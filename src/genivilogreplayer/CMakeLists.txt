cmake_minimum_required(VERSION 2.8)
include(FindPkgConfig)
add_definitions(-std=c++11)
pkg_search_module(GLIB glib-2.0)

set(genivilogreplayer_headers genivilogreplayerplugin.h)
set(genivilogreplayer_sources genivilogreplayerplugin.cpp)

add_library(genivilogreplayerplugin MODULE ${genivilogreplayer_sources})
set_target_properties(genivilogreplayerplugin PROPERTIES PREFIX "")
include_directories(${automotive-message-broker_SRC}/lib ${GLIB_INCLUDE_DIRS})
target_link_libraries(genivilogreplayerplugin amb -L${automotive-message-broker_BIN}/lib)

install(TARGETS genivilogreplayerplugin LIBRARY DESTINATION lib/automotive-message-broker)
