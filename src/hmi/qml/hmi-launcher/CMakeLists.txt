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
# @licence end@
###########################################################################
project(hmi-launcher)
cmake_minimum_required(VERSION 2.8.11)

message(STATUS "hmi-launcher")

find_package(PkgConfig REQUIRED)

pkg_check_modules(DBUS dbus-1)
pkg_check_modules(QT5_CORE REQUIRED Qt5Core)
pkg_check_modules(QT5_QML REQUIRED Qt5Qml)
pkg_check_modules(QT5_QUICK REQUIRED Qt5Quick)
pkg_check_modules(QT5_DBUS REQUIRED Qt5DBus)
pkg_check_modules(QT5_WIDGETS REQUIRED Qt5Widgets)
pkg_check_modules(QT5_GUI REQUIRED Qt5Gui)
pkg_check_modules(QT5_NETWORK REQUIRED Qt5Network)

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
)

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
)

target_link_libraries(hmi-launcher ${LIBRARIES})





