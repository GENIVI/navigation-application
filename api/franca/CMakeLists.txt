###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: whole franca generation
#
# Author: Philippe Colliot
#
# Copyright (C) 2015, PCA Peugeot Citroen 
# 
# Note:
# The current file is an adaptation of the example file
# http://git.projects.genivi.org/?p=ipc/common-api-tools.git;a=blob;f=CommonAPI-Examples/E01HelloWorld/CMakeLists.txt
#
# License:
# This Source Code Form is subject to the terms of the
# Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
# this file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# @licence end@
###########################################################################

cmake_minimum_required (VERSION 2.8.1)

project(whole-franca)

get_directory_property(hasParent PARENT_DIRECTORY)

if(hasParent)
    set(COMMONAPI_GEN_DIR "${COMMONAPI_GEN_DIR}" PARENT_SCOPE)
else()
    set(COMMONAPI_GEN_DIR "${CMAKE_CURRENT_BINARY_DIR}/src-gen")
endif()

option(COMMONAPI_TOOL_DIR
       "Absolute path to CommonAPI tool" "")
option(COMMONAPI_DBUS_TOOL_DIR
       "Absolute path to CommonAPI-DBus tool" "")

if (COMMONAPI_TOOL_DIR)
    message(STATUS "COMMONAPI_TOOL_DIR ${COMMONAPI_TOOL_DIR}")
else ()
    message (FATAL_ERROR "Set the variable -DCOMMONAPI_TOOL_DIR=<path>")
endif ()

if (COMMONAPI_DBUS_TOOL_DIR)
    message(STATUS "COMMONAPI_DBUS_TOOL_DIR ${COMMONAPI_DBUS_TOOL_DIR}")
else ()
    message (FATAL_ERROR "Set the variable -DCOMMONAPI_DBUS_TOOL_DIR=<path>")
endif ()

add_subdirectory(fsa)
add_subdirectory(amb)

