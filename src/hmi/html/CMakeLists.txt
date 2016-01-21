###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: hmi-html
#
# Author: Philippe Colliot
#
# Copyright (C) 2016, PCA Peugeot Citroën
# 
# License:
# This Source Code Form is subject to the terms of the
# Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
# this file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# List of changes:
# DD-MM-YYYY, Name, What
#
# @licence end@
###########################################################################
project(hmi-html)
message(STATUS ${PROJECT_NAME})

cmake_minimum_required(VERSION 2.8.12)

#------------------------------------------------------------------------------
# Check if Emscripten exists and include tool chain macros
#------------------------------------------------------------------------------
set(EMSCRIPTEN_ROOT_PATH "$ENV{EMSCRIPTEN}")
if ("${EMSCRIPTEN_ROOT_PATH}" STREQUAL "")
    message(FATAL_ERROR "Could not locate the Emscripten compiler toolchain directory! Either set the EMSCRIPTEN environment variable, or pass -DEMSCRIPTEN_ROOT_PATH=xxx to CMake to explicitly specify the location of the compiler!")
endif()
include(${EMSCRIPTEN_ROOT_PATH}/cmake/Modules/Platform/Emscripten.cmake)

#------------------------------------------------------------------------------
# Generate the C++ and JavaScript glue code files
#------------------------------------------------------------------------------
find_program(PYTHON python REQUIRED)
set(WEBIDL_BINDER "${EMSCRIPTEN_ROOT_PATH}/tools/webidl_binder.py")
set(WEBIDL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/webidl)
file(GLOB IDL_FILES
        ${WEBIDL_DIR}/*.idl
)
foreach(RAW_FILE ${IDL_FILES})
    get_filename_component(FILE ${RAW_FILE} NAME_WE)
    execute_process(
        COMMAND ${PYTHON} ${WEBIDL_BINDER} ${RAW_FILE} ${CMAKE_CURRENT_BINARY_DIR}/${FILE}_ems
        )
endforeach()

#------------------------------------------------------------------------------
# Set the path of the generated javascript (to be used by the html)
#------------------------------------------------------------------------------
set(JAVASCRIPT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/js)
set(FILE_RESOURCE_IN ${JAVASCRIPT_DIR}/resource.js.in)
set(FILE_RESOURCE_OUT ${JAVASCRIPT_DIR}/resource.js)
set(GENERATED_JAVASCRIPT_PATH ${CMAKE_CURRENT_BINARY_DIR})
configure_file(${FILE_RESOURCE_IN} ${FILE_RESOURCE_OUT} @ONLY)

#------------------------------------------------------------------------------
# Options for building with Emscripten
#------------------------------------------------------------------------------
set(CMAKE_C_COMPILER "${EMSCRIPTEN_ROOT_PATH}/emcc")
set(CMAKE_CXX_COMPILER "${EMSCRIPTEN_ROOT_PATH}/em++")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-warn-absolute-paths -std=gnu++11")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-warn-absolute-paths")

include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${EMSCRIPTEN_ROOT_PATH}/system/include
    ${CMAKE_CURRENT_SOURCE_DIR}/${HMI_HTML_LIB}
)

link_directories(
    ${CMAKE_CURRENT_BINARY_DIR}/${HMI_HTML_LIB}
)

set(PLUGINS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/plugins)

add_executable(${PROJECT_NAME} ${PLUGINS_DIR}/NavigationCoreConfiguration.cpp)
set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "-s ALLOW_MEMORY_GROWTH=1")
em_link_post_js(${PROJECT_NAME} ${CMAKE_CURRENT_BINARY_DIR}/NavigationCoreConfiguration_ems.js)
