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
project(fuel-stop-advisor)
cmake_minimum_required(VERSION 2.8)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=gnu++11")

option(WITH_DEBUG
        "Enable the debug messages" OFF)
option(WITH_FRANCA_INTERFACE
       "Build using the Franca interfaces" OFF)

message(STATUS "WITH_DEBUG = ${WITH_DEBUG}")
message(STATUS "WITH_FRANCA_INTERFACE = ${WITH_FRANCA_INTERFACE}")

set(FUEL_STOP_ADVISOR_API_DIR "${CMAKE_CURRENT_SOURCE_DIR}/fuel-stop-advisor")
set(AUTOMOTIVE_MESSAGE_BROKER "automotive-message-broker")
set(AUTOMOTIVE_MESSAGE_BROKER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${AUTOMOTIVE_MESSAGE_BROKER}")
set(AUTOMOTIVE_MESSAGE_BROKER_SRC_DIR "${AUTOMOTIVE_MESSAGE_BROKER_DIR}/src/${AUTOMOTIVE_MESSAGE_BROKER}")
set(AUTOMOTIVE_MESSAGE_BROKER_BIN_DIR "${AUTOMOTIVE_MESSAGE_BROKER_DIR}/src/${AUTOMOTIVE_MESSAGE_BROKER}-build")
set(AUTOMOTIVE_MESSAGE_BROKER_LIB_DIR "${AUTOMOTIVE_MESSAGE_BROKER_BIN_DIR}/lib")
set(PATCH_DIR "${CMAKE_CURRENT_SOURCE_DIR}/patches")
set(NAVIT_PNG_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}/navigation/navit/navit/navit/xpm")
set(HMI_QML_DIR "${CMAKE_CURRENT_SOURCE_DIR}/hmi/qml")

include(ExternalProject)
ExternalProject_Add(${AUTOMOTIVE_MESSAGE_BROKER}
PREFIX ${AUTOMOTIVE_MESSAGE_BROKER_DIR}
GIT_REPOSITORY  https://github.com/otcshare/automotive-message-broker.git
GIT_TAG c216955d16ca275159891cad296217094d972390
UPDATE_COMMAND ""
PATCH_COMMAND patch -p1 -i "${PATCH_DIR}/amb_allow_sessionbus.patch"
INSTALL_COMMAND sudo make install
)

add_subdirectory(navigation/src/navigation "${CMAKE_CURRENT_BINARY_DIR}/navigation")

add_subdirectory(fuel-stop-advisor)

add_subdirectory(genivilogreplayer)

add_subdirectory(hmi/qml/hmi-launcher)

add_subdirectory(navigation/src/poi-service "${CMAKE_CURRENT_BINARY_DIR}/poi-service")
