###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: Navit POC
#
# Author: Martin Schaller <martin.schaller@it-schaller.de>
#
# 
# License:
# This Source Code Form is subject to the terms of the
# Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
# this file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# @licence end@
###########################################################################
cmake_minimum_required(VERSION 2.8)

add_definitions("-std=gnu++11")

include(FindPkgConfig)

pkg_search_module(DBUS_CPP_GLIB dbus-c++-glib-1)
pkg_search_module(DBUS_CPP dbus-c++-1)
pkg_search_module(GLIB glib-2.0)

include_directories(
    ${GLIB_INCLUDE_DIRS}
    ${DBUS_CPP_INCLUDE_DIRS}
    ${DBUS_CPP_GLIB_INCLUDE_DIRS}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${DBUS_GENERATED_INCLUDE_DIR_PARENT_SCOPE}/navigation-core
    ${TRIPCOMPUTER_DIR}
    )

message(STATUS "WITH_DEBUG = ${WITH_DEBUG}")

if(WITH_DEBUG)
    add_definitions("-DDEBUG_ENABLED=1")
endif()

message(STATUS "generation of DBus files for fuel-stop-advisor")

find_program(XSLTPROC xsltproc REQUIRED)
find_program(DBUSXML2CPP dbusxx-xml2cpp REQUIRED)

file (GLOB XML_TO_DBUS 
	${CMAKE_CURRENT_SOURCE_DIR}/fuel-stop-advisor.xml
	${CMAKE_CURRENT_SOURCE_DIR}/amb.xml
)
foreach (RAW_FILE ${XML_TO_DBUS})
	get_filename_component(FILE ${RAW_FILE} NAME_WE)
	execute_process(
		COMMAND ${DBUSXML2CPP} ${RAW_FILE} --proxy=${CMAKE_CURRENT_BINARY_DIR}/${FILE}_proxy.h  
		COMMAND ${DBUSXML2CPP} ${RAW_FILE} --adaptor=${CMAKE_CURRENT_BINARY_DIR}/${FILE}_adaptor.h  
	)
endforeach()

file (GLOB XML_TO_DBUS_CONSTANT
	${CMAKE_CURRENT_SOURCE_DIR}/constants.xml
)
foreach (RAW_FILE ${XML_TO_DBUS_CONSTANT})
	get_filename_component(FILE ${RAW_FILE} NAME_WE)
	execute_process(
		OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.h
		COMMAND ${XSLTPROC} ${CMAKE_CURRENT_SOURCE_DIR}/enum.xsl ${RAW_FILE}        
	)
endforeach()

add_executable(fuel-stop-advisor fuel-stop-advisor.cpp  ${TRIPCOMPUTER_DIR}/ctripcomputer.cpp)

set(LIBRARIES
    ${DBUS_CPP_LIBRARIES}
    ${GLIB_LIBRARIES}
    ${DBUS_CPP_GLIB_LIBRARIES}
)

target_link_libraries(fuel-stop-advisor ${LIBRARIES})
