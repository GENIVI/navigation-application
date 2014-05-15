###########################################################################
# Component Name: Navit POC
# Author: Martin Schaller <martin.schaller@it-schaller.de>
#
# Copyright (C) 2012, GENIVI Alliance, Inc.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as 
# published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
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
ADD_CUSTOM_COMMAND(OUTPUT genivi-navigationcore-routing_adaptor.h
		   COMMAND dbusxx-xml2cpp ${genivi-navigationcore-routing_API} --adaptor=genivi-navigationcore-routing_adaptor.h
		   DEPENDS ${genivi-navigationcore-routing_API}
		   )
ADD_CUSTOM_COMMAND(OUTPUT genivi-navigationcore-constants.h
	           COMMAND xsltproc ${PROJECT_SOURCE_DIR}/enum.xsl ${genivi-navigationcore-constants_API} >genivi-navigationcore-constants.h
		   DEPENDS ${genivi-navigationcore-constants_API}
		   )
ADD_CUSTOM_COMMAND(OUTPUT amb.h
		   COMMAND dbusxx-xml2cpp ${PROJECT_SOURCE_DIR}/amb.xml --proxy=amb.h
		   DEPENDS amb.xml
		   )
ADD_CUSTOM_COMMAND(OUTPUT constants.h
	           COMMAND xsltproc ${PROJECT_SOURCE_DIR}/enum.xsl ${PROJECT_SOURCE_DIR}/constants.xml >constants.h
		   DEPENDS constants.xml
		   )
add_executable(fuel-stop-advisor fuel-stop-advisor.cpp fuel-stop-advisor.h constants.h genivi-navigationcore-routing_adaptor.h amb.h genivi-navigationcore-constants.h)
target_link_libraries(fuel-stop-advisor ${DBUS_CPP_LDFLAGS} ${GLIB_LDFLAGS})
