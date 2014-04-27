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
ADD_CUSTOM_COMMAND(OUTPUT tripcomputer.h
		   COMMAND dbusxx-xml2cpp ${PROJECT_SOURCE_DIR}/tripcomputer.xml --adaptor=tripcomputer.h
		   DEPENDS tripcomputer.xml
		   )
ADD_CUSTOM_COMMAND(OUTPUT constants.h
	           COMMAND xsltproc ${PROJECT_SOURCE_DIR}/enum.xsl ${PROJECT_SOURCE_DIR}/constants.xml >constants.h
		   DEPENDS constants.xml
		   )
add_executable(tripcomputer tripcomputer.cpp tripcomputer.h constants.h)
target_link_libraries(tripcomputer ${DBUS_CPP_LDFLAGS} ${GLIB_LDFLAGS})
