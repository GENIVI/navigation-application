###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: Vehicle gateway
#
# Author: Philippe Colliot
#
# Copyright (C) 2017, PSA GROUP
#
# Former code made by Marco Residori
#
# Copyright (C) 2013, XS Embedded GmbH
# 
# License:
# This Source Code Form is subject to the terms of the
# Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
# this file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# @licence end@
###########################################################################
project(vehicle-gateway)
cmake_minimum_required(VERSION 2.8)

message(STATUS ${PROJECT_NAME})

add_definitions("-std=gnu++11")

message(STATUS "WITH_DLT = ${WITH_DLT}")

find_package(PkgConfig REQUIRED)

set(PRJ_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/veh-gateway.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/obd2.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/hnmea.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/gnss.cpp
)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
)

set(LIBRARIES pthread)

if(WITH_DLT)
    pkg_check_modules(DLT REQUIRED automotive-dlt)
    add_definitions("-DDLT_ENABLED=1")
    include_directories( ${DLT_INCLUDE_DIRS} )
    set(LIBRARIES ${LIBRARIES} ${DLT_LIBRARIES})
endif()

add_executable(${PROJECT_NAME} ${PRJ_SRCS})

target_link_libraries(${PROJECT_NAME} ${LIBRARIES})

install(TARGETS ${PROJECT_NAME} DESTINATION bin)




