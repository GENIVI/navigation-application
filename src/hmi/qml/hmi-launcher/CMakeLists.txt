###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: hmi-launcher
#
# Author: Philippe Colliot
#
# Copyright (C) 2014, PCA Peugeot Citroën
# 
# License:
# This Source Code Form is subject to the terms of the
# Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
# this file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# List of changes:
# 13-10-2014, Tanibata, Nobuhiko, adaptation to layer management
#
# @licence end@
###########################################################################
project(hmi-launcher)
cmake_minimum_required(VERSION 2.8.11)

message(STATUS "hmi-launcher")
find_program(XSLTPROC xsltproc REQUIRED)

find_package(PkgConfig REQUIRED)

pkg_check_modules(DBUS dbus-1)
pkg_check_modules(QT5_CORE REQUIRED Qt5Core)
pkg_check_modules(QT5_QML REQUIRED Qt5Qml)
pkg_check_modules(QT5_QUICK REQUIRED Qt5Quick)
pkg_check_modules(QT5_DBUS REQUIRED Qt5DBus)
pkg_check_modules(QT5_WIDGETS REQUIRED Qt5Widgets)
pkg_check_modules(QT5_GUI REQUIRED Qt5Gui)
pkg_check_modules(QT5_NETWORK REQUIRED Qt5Network)
pkg_check_modules(QT5_OPENGL REQUIRED glesv2)


if (${LM} EQUAL 1 )
	message("building with layer management")
	set(ILM_LIBRARIES "-lilmCommon -lilmClient -lilmControl")
	include_directories(${QT5_OPENGL_INCLUDE_DIRS})
	include_directories(${ILM_INCLUDE_DIRS})
	file(GLOB ILM_SOURCES lm_control.cpp lm_control.h)
	add_definitions(-DLM)
else()
	message("building without layer management")
endif()


include_directories(${CMAKE_CURRENT_BINARY_DIR})
include_directories(${QT5_CORE_INCLUDE_DIRS})
include_directories(${QT5_QML_INCLUDE_DIRS})
include_directories(${QT5_QUICK_INCLUDE_DIRS})
include_directories(${QT5_DBUS_INCLUDE_DIRS})
include_directories(${QT5_WIDGETS_INCLUDE_DIRS})
include_directories(${QT5_GUI_INCLUDE_DIRS})
include_directories(${QT5_NETWORK_INCLUDE_DIRS})
include_directories(${DBUS_INCLUDE_DIRS})

set(cmake_create_dir cmake -E make_directory)

#settings for Qt
set(CMAKE_XXX_FLAGS "${CMAKE_XXX_FLAGS} ${QT5_EXECUTABLE_COMPILE_FLAGS}")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
add_definitions(${QT5_CORE_DEFINITIONS})
add_definitions(-DQT_PLUGIN)
add_definitions(-DQT_NO_DEBUG)
set(qt_moc moc -o)
set(MOC moc)
set(MOC_DIR ${CMAKE_CURRENT_BINARY_DIR}/${MOC})

link_directories(
	${QT5_CORE_LIBRARY_DIRS}
	${QT5_QML_LIBRARY_DIRS}
	${QT5_QUICK_LIBRARY_DIRS}
	${QT5_DBUS_LIBRARY_DIRS}
	${QT5_WIDGETS_LIBRARY_DIRS}
	${QT5_GUI_LIBRARY_DIRS}
	${QT5_NETWORK_LIBRARY_DIRS}
	${DBUS_LIBRARY_DIRS}
	${QT5_OPENGL_LIBRARY_DIRS}
	${ILM_LIBRARY_DIRS}
)
 
set(LIBRARIES 
    ${QT5_CORE_LIBRARIES}
    ${QT5_QML_LIBRARIES}
    ${QT5_QUICK_LIBRARIES}
    ${QT5_DBUS_LIBRARIES}
    ${QT5_WIDGETS_LIBRARIES}
    ${QT5_GUI_LIBRARIES}
    ${QT5_NETWORK_LIBRARIES}
	${DBUS_LIBRARIES}
	${QT5_OPENGL_LIBRARIES}
	${ILM_LIBRARIES}
)

# generate constants used by the QML files
# in order to generate it, navigation-service and positioning have to be being cloned before
# do cmake -Dnavigation-service_API=<path to navigation-service APIs> -Dpositioning_API=<path to positioning enhanced position API>
file (GLOB XML_TO_CONSTANTS
	${navigation-service_API}/map-viewer/genivi-mapviewer-constants.xml
	${navigation-service_API}/navigation-core/genivi-navigationcore-constants.xml
	${navigation-service_API}/poi-service/genivi-poiservice-constants.xml
	${positioning_API}/genivi-positioning-constants.xml
)
if(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/constants.js)
	foreach (RAW_FILE ${XML_TO_CONSTANTS})
		get_filename_component(FILE ${RAW_FILE} NAME_WE)
		execute_process(
			OUTPUT_VARIABLE data_flow
			COMMAND ${XSLTPROC} ${CMAKE_CURRENT_SOURCE_DIR}/../javascript.xsl ${RAW_FILE}        
		)
		file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/constants.js ${data_flow})
	endforeach()
endif()

# for some reason, automoc doesn't run, so moc is made manually
set (SRC_TO_MOC ${CMAKE_CURRENT_SOURCE_DIR}/dbusif.h
				${CMAKE_CURRENT_SOURCE_DIR}/dbusifsignal.h
				${CMAKE_CURRENT_SOURCE_DIR}/wheelarea.h
				${CMAKE_CURRENT_SOURCE_DIR}/wheelareaplugin.h
				${CMAKE_CURRENT_SOURCE_DIR}/preference.h
)
execute_process(
	COMMAND ${cmake_create_dir} ${MOC}
)
foreach (RAW_FILE ${SRC_TO_MOC})
	get_filename_component(FILE ${RAW_FILE} NAME_WE)
	if(NOT EXISTS ${MOC_DIR}/moc_${FILE}.cpp)
		execute_process(
			COMMAND ${qt_moc} "${MOC_DIR}/moc_${FILE}.cpp" ${RAW_FILE} 
		)
	else()
		if(${RAW_FILE} IS_NEWER_THAN ${MOC_DIR}/moc_${FILE}.cpp)
			execute_process(
				COMMAND ${qt_moc} "${MOC_DIR}/moc_${FILE}.cpp" ${RAW_FILE} 
			)
		endif()
	endif()
endforeach()
file(GLOB MOC_SOURCES ${MOC_DIR}/moc_*.cpp)

add_executable(hmi-launcher
	${MOC_SOURCES}
	main.cpp
    dbusif.cpp
    wheelareaplugin.cpp
	wheelareaplugin.h
    preference.cpp
	dbusif.h 
    dbusifsignal.h 
    wheelarea.h 
    preference.h
	${ILM_SOURCES}
)

target_link_libraries(hmi-launcher ${LIBRARIES})





