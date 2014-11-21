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
include(FindPkgConfig)
pkg_search_module(DBUS_CPP dbus-c++-glib-1 dbus-c++-1)
pkg_search_module(GLIB glib-2.0)
include_directories(${DBUS_CPP_INCLUDE_DIRS} ${GLIB_INCLUDE_DIRS} ${CMAKE_CURRENT_BINARY_DIR})

ADD_CUSTOM_COMMAND(OUTPUT fuel-stop-advisor.h
		   COMMAND dbusxx-xml2cpp ${PROJECT_SOURCE_DIR}/fuel-stop-advisor.xml --adaptor=fuel-stop-advisor.h
		   DEPENDS fuel-stop-advisor.xml
		   )
ADD_CUSTOM_COMMAND(OUTPUT amb.h
		   COMMAND dbusxx-xml2cpp ${PROJECT_SOURCE_DIR}/amb.xml --proxy=amb.h
		   DEPENDS amb.xml
		   )
ADD_CUSTOM_COMMAND(OUTPUT constants.h
	           COMMAND xsltproc ${PROJECT_SOURCE_DIR}/enum.xsl ${PROJECT_SOURCE_DIR}/constants.xml >constants.h
		   DEPENDS constants.xml
		   )
message(STATUS "WITH_DEBUG = ${WITH_DEBUG}")

if(WITH_DEBUG)
    add_definitions("-DDEBUG_ENABLED=1")
endif()

include_directories(${generated_api_DIR})

add_executable(fuel-stop-advisor fuel-stop-advisor.cpp fuel-stop-advisor.h constants.h ${generated_api_DIR}/genivi-navigationcore-routing_proxy.h amb.h ${generated_api_DIR}/genivi-navigationcore-constants.h ctripcomputer.cpp ctripcomputer.h ctripcomputertypes.h)
target_link_libraries(fuel-stop-advisor ${DBUS_CPP_LDFLAGS} ${GLIB_LDFLAGS})
