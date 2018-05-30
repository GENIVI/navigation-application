###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: log-replayer-server
#
# Author: Philippe Colliot
#
# Copyright (C) 2018, Groupe PSA
#
# License:
# This Source Code Form is subject to the terms of the
# Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
# this file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# @licence end@
###########################################################################
project(log-replayer-server)
cmake_minimum_required(VERSION 2.8)

message(STATUS ${PROJECT_NAME})

set(CMAKE_VERBOSE_MAKEFILE on)
set(CMAKE_CXX_FLAGS "-Wall -std=c++0x")

# Source Files
FILE(GLOB PRJ_LOCAL_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)

set(PRJ_SRCS ${PRJ_LOCAL_SRCS})

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${TOP_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${TOP_DIR}/bin)

include_directories(
    ${GOBJECT_INCLUDE_DIRS}
    ${GLIB_INCLUDE_DIRS}
)

link_directories(
    ${GOBJECT_LIBRARY_DIRS}
    ${GLIB_LIBRARY_DIRS}
)

set(LIBRARIES
    ${LIBRARIES}
    ${GOBJECT_LIBRARIES}
    ${GLIB_LIBRARIES}
)

# Build service
add_executable(${PROJECT_NAME} ${PRJ_SRCS})
target_link_libraries(${PROJECT_NAME} ${LIBRARIES})
install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
