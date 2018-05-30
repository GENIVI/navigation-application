###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: fuel stop advisor application
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
project(genivilogreplayerplugin)

message(STATUS ${PROJECT_NAME})

cmake_minimum_required(VERSION 2.8)

add_definitions("-std=gnu++11")

include(FindPkgConfig)
pkg_search_module(GLIB glib-2.0)

set(genivilogreplayer_headers genivilogreplayerplugin.h)
set(genivilogreplayer_sources genivilogreplayerplugin.cpp)

add_library(${PROJECT_NAME} MODULE ${genivilogreplayer_sources})
set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")
include_directories(${AUTOMOTIVE_MESSAGE_BROKER_SRC_DIR}/lib ${GLIB_INCLUDE_DIRS})
target_link_libraries(${PROJECT_NAME} amb -L${AUTOMOTIVE_MESSAGE_BROKER_LIB_DIR})

install(TARGETS ${PROJECT_NAME} LIBRARY DESTINATION lib/automotive-message-broker)
