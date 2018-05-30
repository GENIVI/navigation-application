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
# List of changes:
# 13-10-2014, Tanibata, Nobuhiko, adaptation to layer management
#
# @licence end@
###########################################################################
project(hmi-launcher)

message(STATUS ${PROJECT_NAME})

cmake_minimum_required(VERSION 2.8.11)

add_definitions("-std=gnu++11")

add_definitions("-fPIC")

find_program(XSLTPROC xsltproc REQUIRED)
find_program(QT_MOC_EXECUTABLE moc)
find_program(QT_LRELEASE lrelease)
find_program(QT_LUPDATE lupdate)

find_package(PkgConfig REQUIRED)

set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${TOP_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${TOP_DIR}/bin)

pkg_check_modules(DBUS dbus-1)
pkg_check_modules(QT5_CORE REQUIRED Qt5Core)
pkg_check_modules(QT5_QML REQUIRED Qt5Qml)
pkg_check_modules(QT5_QUICK REQUIRED Qt5Quick)
pkg_check_modules(QT5_DBUS REQUIRED Qt5DBus)
pkg_check_modules(QT5_WIDGETS REQUIRED Qt5Widgets)
pkg_check_modules(QT5_GUI REQUIRED Qt5Gui)
pkg_check_modules(QT5_NETWORK REQUIRED Qt5Network)

include_directories(
    ${CMAKE_CURRENT_BINARY_DIR}
    ${QT5_CORE_INCLUDE_DIRS}
    ${QT5_QML_INCLUDE_DIRS}
    ${QT5_QUICK_INCLUDE_DIRS}
    ${QT5_DBUS_INCLUDE_DIRS}
    ${QT5_WIDGETS_INCLUDE_DIRS}
    ${QT5_GUI_INCLUDE_DIRS}
    ${QT5_NETWORK_INCLUDE_DIRS}
    ${DBUS_INCLUDE_DIRS}
    ${NAVIGATION_COMMON_DIR}
)

set(cmake_create_dir cmake -E make_directory)

# settings for Qt
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${QT5_EXECUTABLE_COMPILE_FLAGS}")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
add_definitions(${QT5_CORE_DEFINITIONS})
add_definitions(-DQT_PLUGIN)
add_definitions(-DQT_NO_DEBUG)

if(QT_MOC_EXECUTABLE)
    set(qt_moc ${QT_MOC_EXECUTABLE} -o)
else()
    set(qt_moc moc -o)
endif()

if(QT_LRELEASE)
    set(qt_release ${QT_LRELEASE} -markuntranslated ?)
else()
    set(qt_release lrelease -markuntranslated ?)
endif()
if(QT_LUPDATE)
    set(qt_update ${QT_LUPDATE})
else()
    set(qt_update lupdate)
endif()

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
    ${LIBRARIES}
    ${QT5_CORE_LIBRARIES}
    ${QT5_QML_LIBRARIES}
    ${QT5_QUICK_LIBRARIES}
    ${QT5_DBUS_LIBRARIES}
    ${QT5_WIDGETS_LIBRARIES}
    ${QT5_GUI_LIBRARIES}
    ${QT5_NETWORK_LIBRARIES}
    ${DBUS_LIBRARIES}
)

# generate constants used by the QML files
# in order to generate it, navigation-service and positioning have to be being cloned before
file (GLOB XML_TO_CONSTANTS
    ${NAVIGATION_API_DIR}/map-viewer/genivi-mapviewer-constants.xml
    ${NAVIGATION_API_DIR}/navigation-core/genivi-navigationcore-constants.xml
    ${NAVIGATION_API_DIR}/poi-service/genivi-poiservice-constants.xml
    ${POSITIONING_API_DIR}/genivi-positioning-constants.xml
    ${FUEL_STOP_ADVISOR_API_DIR}/constants.xml
)
if(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/constants.js)
    foreach (RAW_FILE ${XML_TO_CONSTANTS})
            get_filename_component(FILE ${RAW_FILE} NAME_WE)
            execute_process(
                    OUTPUT_VARIABLE data_flow
                    COMMAND ${XSLTPROC} ${CMAKE_CURRENT_SOURCE_DIR}/../qml/javascript.xsl ${RAW_FILE}
            )
            file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/constants.js ${data_flow})
    endforeach()
endif()

# set the paths into the resource.js file
set(FILE_RESOURCE_IN ${CMAKE_CURRENT_SOURCE_DIR}/../qml/Core/resource.js.in)
set(FILE_RESOURCE_OUT ${CMAKE_CURRENT_SOURCE_DIR}/../qml/Core/resource.js)
set(CONSTANTS_PATH ${CMAKE_CURRENT_BINARY_DIR})
set(ICON_PATH ${NAVIT_PNG_BIN_DIR})
configure_file(${FILE_RESOURCE_IN} ${FILE_RESOURCE_OUT} @ONLY)

#generate or update ts files
execute_process(
    COMMAND ${qt_update} ${CMAKE_CURRENT_SOURCE_DIR}/../translations/translating-qml.pro
)

#generate qm files
file (GLOB TS_TO_RELEASE
    ${CMAKE_CURRENT_SOURCE_DIR}/../translations/*.ts
)

foreach(RAW_FILE ${TS_TO_RELEASE})
    get_filename_component(FILE ${RAW_FILE} NAME_WE)
    if(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.qm)
        execute_process(
            COMMAND ${qt_release} ${RAW_FILE} -qm ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.qm
        )
    else()
        if(${RAW_FILE} IS_NEWER_THAN ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.qm)
            execute_process(
            COMMAND ${qt_release} ${RAW_FILE} -qm ${CMAKE_CURRENT_BINARY_DIR}/${FILE}.qm
            )
        endif()
    endif()
endforeach()

# for some reason, automoc doesn't run, so moc is made manually
set (SRC_TO_MOC
    ${CMAKE_CURRENT_SOURCE_DIR}/dbusif.h
    ${CMAKE_CURRENT_SOURCE_DIR}/dltif.h
    ${CMAKE_CURRENT_SOURCE_DIR}/dbusifsignal.h
    ${CMAKE_CURRENT_SOURCE_DIR}/wheelarea.h
    ${CMAKE_CURRENT_SOURCE_DIR}/wheelareaplugin.h
    ${CMAKE_CURRENT_SOURCE_DIR}/preference.h
    ${CMAKE_CURRENT_SOURCE_DIR}/settings.h
    ${CMAKE_CURRENT_SOURCE_DIR}/translator.h
)
execute_process(
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
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

if(${WITH_DEBUG})
    add_definitions("-DDEBUG_ENABLED=1")
endif()

if(${WITH_DLT})
    add_definitions("-DDLT_ENABLED=1")
    pkg_check_modules(DLT REQUIRED automotive-dlt)
    include_directories( ${DLT_INCLUDE_DIRS} )
    set(LIBRARIES ${LIBRARIES} ${DLT_LIBRARIES})
endif()

add_executable(${PROJECT_NAME}
    ${MOC_SOURCES}
    main.cpp
    dltif.cpp
    dbusif.cpp
    wheelareaplugin.cpp
    preference.cpp
)

target_link_libraries(${PROJECT_NAME} ${LIBRARIES})

install(TARGETS ${PROJECT_NAME} DESTINATION bin)





