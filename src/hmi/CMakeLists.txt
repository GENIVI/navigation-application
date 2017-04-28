###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: hmi
#
# Author: Philippe Colliot
#
# Copyright (C) 2017, PCA Peugeot Citroën
# 
# License:
# This Source Code Form is subject to the terms of the
# Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
# this file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
#
# @licence end@
###########################################################################
project(hmi)
cmake_minimum_required(VERSION 2.8.11)
message(STATUS ${PROJECT_NAME})

add_definitions("-std=gnu++11")

add_definitions("-fPIC")

set(STYLESHEET_GENERATOR ./style_sheet_generator.sh)
set(GIMP_FILES_DIRECTORY ./gimp/gdp-theme/800x480)
set(STYLE_SHEETS_GENERATED_INDICATOR "./style-sheets/the-style-sheets-have-been-generated-css.js")

if(${WITH_STYLESHEET})
	FILE(GLOB IMAGE_FILES_TO_REMOVE ${CMAKE_CURRENT_SOURCE_DIR}/images/*.png)
	FILE(GLOB STYLESHEET_FILES_TO_REMOVE ${CMAKE_CURRENT_SOURCE_DIR}/style-sheets/*-css.js)
    	execute_process(
		COMMAND rm -rf ${IMAGE_FILES_TO_REMOVE}
		COMMAND rm -rf ${STYLESHEET_FILES_TO_REMOVE}
		COMMAND bash ${STYLESHEET_GENERATOR} -i ${GIMP_FILES_DIRECTORY} -o ${CMAKE_CURRENT_SOURCE_DIR} -v -nl
		COMMAND touch ${STYLE_SHEETS_GENERATED_INDICATOR}
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
	)
endif()

if (WITH_PLUGIN_MIGRATION)
    execute_process(
        COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/qml/Core/genivi-capi.js ${CMAKE_CURRENT_SOURCE_DIR}/qml/Core/genivi.js
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
else()
    execute_process(
        COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/qml/Core/genivi-origin.js ${CMAKE_CURRENT_SOURCE_DIR}/qml/Core/genivi.js
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
endif()

add_subdirectory(hmi-launcher)







