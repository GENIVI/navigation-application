###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: SensorsService
#
# Author: Marco Residori
#
# Copyright (C) 2013, XS Embedded GmbH
# Copyright (C) 2018, PSA Groupe
# 
# License:
# This Source Code Form is subject to the terms of the
# Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
# this file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Update (2014/12/02) : Philippe Colliot <philippe.colliot@mpsa.com>,
#				PSA Peugeot Citroen
#		- introduce debug flag to disable verbosity
# Update (2018/05/30) : Philippe Colliot <philippe.colliot@mpsa.com>,
#				PSA Groupe
#		- adaptation of former version to introduce dead reckoning
# @licence end@
###########################################################################
project(sensors-service)

message(STATUS ${PROJECT_NAME})

add_definitions("-std=gnu++11")

find_package(PkgConfig REQUIRED)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${TOP_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${TOP_DIR}/bin)

include_directories("${SENSORS_SERVICE_API_DIR}")

set(LIBRARIES pthread)

if(WITH_DLT)
    add_definitions("-DDLT_ENABLED=1")
    pkg_check_modules(DLT REQUIRED automotive-dlt)
    include_directories( ${DLT_INCLUDE_DIRS} )
    set(LIBRARIES ${LIBRARIES} ${DLT_LIBRARIES})
endif()

if(WITH_DEBUG)
    add_definitions("-DDEBUG_ENABLED=1")
endif()

#generate library using replayer as input
set(SRC ${CMAKE_CURRENT_SOURCE_DIR}/sns-use-replayer.c 
     ${CMAKE_CURRENT_SOURCE_DIR}/wheeltick.c 
     ${CMAKE_CURRENT_SOURCE_DIR}/gyroscope.c 
     ${CMAKE_CURRENT_SOURCE_DIR}/acceleration.c
     ${CMAKE_CURRENT_SOURCE_DIR}/vehicle-data.c
     ${CMAKE_CURRENT_SOURCE_DIR}/vehicle-speed.c
     ${CMAKE_CURRENT_SOURCE_DIR}/sns-meta-data.c)

add_library(${PROJECT_NAME} SHARED ${SRC})
target_link_libraries(${PROJECT_NAME} ${LIBRARIES})
install(TARGETS ${PROJECT_NAME} DESTINATION lib)















