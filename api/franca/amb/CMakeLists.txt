###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: franca navigation poi service generation
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

project(franca-amb)

option(COMMONAPI_TOOL_DIR
       "Absolute path to CommonAPI tool" "")
option(COMMONAPI_DBUS_TOOL_DIR
       "Absolute path to CommonAPI-DBus tool" "")

execute_process(COMMAND uname -i OUTPUT_VARIABLE OS_VERSION)
if("${OS_VERSION}" MATCHES "i686")
  set(OS_VERSION "x86")
else()
  set(OS_VERSION "x86_64")
endif()
message(STATUS "OS_VERSION = ${OS_VERSION}")

set(COMMONAPI_FIDL_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

find_package(PkgConfig REQUIRED)

include(FindPkgConfig)

# generate code from fidl
if(NOT COMMONAPI_GEN_DIR)
     message (FATAL_ERROR "Set the variable -DCOMMONAPI_GEN_DIR=<path>")
endif()

file(GLOB FIDL_FILES "${COMMONAPI_FIDL_DIR}/*.fidl")

if (COMMONAPI_TOOL_DIR)
     execute_process(WORKING_DIRECTORY ${COMMONAPI_FIDL_DIR}
                COMMAND ${COMMONAPI_TOOL_DIR}/org.genivi.commonapi.core.cli.product/target/products/org.genivi.commonapi.core.cli.product/linux/gtk/${OS_VERSION}/commonapi-generator-linux-${OS_VERSION} -sk -d ${COMMONAPI_GEN_DIR} ${FIDL_FILES})
else ()
    message (FATAL_ERROR "Set the variable -DCOMMONAPI_TOOL_DIR=<path>")
endif ()

if (COMMONAPI_DBUS_TOOL_DIR)
    execute_process(WORKING_DIRECTORY ${COMMONAPI_FIDL_DIR}
                COMMAND ${COMMONAPI_DBUS_TOOL_DIR}/org.genivi.commonapi.dbus.cli.product/target/products/org.genivi.commonapi.dbus.cli.product/linux/gtk/${OS_VERSION}/commonapi-dbus-generator-linux-${OS_VERSION} -d ${COMMONAPI_GEN_DIR} ${FIDL_FILES})
else ()
    message (FATAL_ERROR "Set the variable -DCOMMONAPI_DBUS_TOOL_DIR=<path>")
endif ()

