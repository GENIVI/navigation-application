###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: fuel-stop-advisor-capi
#
# Author: Philippe Colliot
#
# Copyright (C) 2015, PCA Peugeot Citroën
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

message(STATUS ${PROJECT_NAME})

set(CMAKE_VERBOSE_MAKEFILE on)
set(CMAKE_CXX_FLAGS "-Wall -std=c++0x")
add_definitions("-std=gnu++11")

include(FindPkgConfig)

message(STATUS "generation of DBus files for AMB")

find_program(DBUSXML2CPP dbusxx-xml2cpp REQUIRED)

file (GLOB XML_TO_DBUS
        ${CMAKE_CURRENT_SOURCE_DIR}/amb.xml
)
foreach (RAW_FILE ${XML_TO_DBUS})
        get_filename_component(FILE ${RAW_FILE} NAME_WE)
        execute_process(
                COMMAND ${DBUSXML2CPP} ${RAW_FILE} --proxy=${CMAKE_CURRENT_BINARY_DIR}/${FILE}_proxy.h
                COMMAND ${DBUSXML2CPP} ${RAW_FILE} --adaptor=${CMAKE_CURRENT_BINARY_DIR}/${FILE}_adaptor.h
        )
endforeach()


# DBus Path
if(DBUS_LIB_PATH)
  set(DBUS_INCLUDE_DIRS ${DBUS_LIB_PATH}/include/dbus-1.0 ${DBUS_LIB_PATH}/lib/dbus-1.0/include)
  set(DBUS_LIBDIR ${DBUS_LIB_PATH}/lib)
  set(DBUS_LIBRARIES ${DBUS_LIB_PATH}/lib/libdbus-1.so)
else()
  message(FATAL_ERROR "Please specify the path to your patched DBus library using -DDBUS_LIB_PATH=yourPath")
endif()

# Packages
find_package(CommonAPI 3.1.5 REQUIRED)
find_package(CommonAPI-DBus 3.1.5 REQUIRED)

# pkg_check_modules(DBUS "dbus-1 >= 1.8.4") // #to be fixed, it doesn't work so the paths are set manually (see above)
pkg_check_modules(COMMONAPI "CommonAPI >= 3.1.5")
pkg_check_modules(COMMONAPI_DBUS "CommonAPI-DBus >= 3.1.5")
pkg_check_modules(GOBJECT gobject-2.0)
pkg_check_modules(GLIB REQUIRED glib-2.0)
pkg_check_modules(DBUS_CPP_GLIB dbus-c++-glib-1)
pkg_search_module(DBUS_CPP dbus-c++-1)

# generates the CommonAPI templates from the Franca files
set(COMMONAPI_GEN_DIR "${CMAKE_CURRENT_BINARY_DIR}/franca/src-gen")

# for Navigation routing
set(API_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../navigation/api")
add_subdirectory(${API_DIR}/franca/navigation/navigationcore "${CMAKE_CURRENT_BINARY_DIR}/franca")
set(API_VERSION_MAJOR 4)
set(API_VERSION "v${API_VERSION_MAJOR}")
set(PRJ_SRC_GEN_ROOT_PATH ${COMMONAPI_GEN_DIR}/${API_VERSION}/org/genivi) #files shared by all the APIs
set(PRJ_SRC_GEN_NAVIGATION_PATH ${PRJ_SRC_GEN_ROOT_PATH}/navigation) #files shared by the navigation APIs
set(PRJ_SRC_GEN_NAVIGATIONCORE_PATH ${PRJ_SRC_GEN_NAVIGATION_PATH}/navigationcore) #files shared by the navigationcore APIs

# for FSA
set(API_DIR_FSA "${CMAKE_CURRENT_SOURCE_DIR}/../../api")
add_subdirectory(${API_DIR_FSA}/franca "${CMAKE_CURRENT_BINARY_DIR}/franca-fsa")
set(PRJ_SRC_GEN_DEMONSTRATOR_PATH ${COMMONAPI_GEN_DIR}/v1/org/genivi/demonstrator) #files shared by the demonstrator APIs

# Source Files
set(FRANCA_FILE "FuelStopAdvisor")
FILE(GLOB PRJ_LOCAL_SRCS fuel-stop-advisor.cpp)
FILE(GLOB PRJ_TRIPCOMPUTER_SRCS ${TRIPCOMPUTER_DIR}/ctripcomputer.cpp)
FILE(GLOB PRJ_STUB_GEN_SRCS
    ${PRJ_SRC_GEN_DEMONSTRATOR_PATH}/${FRANCA_FILE}DBusStub*.cpp ${PRJ_SRC_GEN_DEMONSTRATOR_PATH}/${FRANCA_FILE}Types.cpp ${PRJ_SRC_GEN_DEMONSTRATOR_PATH}/${FRANCA_FILE}DBusDeployment.cpp ${PRJ_SRC_GEN_DEMONSTRATOR_PATH}/${FRANCA_FILE}StubDefault.cpp
    )
FILE(GLOB PRJ_STUB_IMPL_SRCS
    ${PRJ_SRC_GEN_DEMONSTRATOR_PATH}/${FRANCA_FILE}Stub*.cpp
    )

set(FRANCA_FILE_CLIENT "Routing")
FILE(GLOB PRJ_PROXY_GEN_SRCS
    ${PRJ_SRC_GEN_NAVIGATIONCORE_PATH}/${FRANCA_FILE_CLIENT}*DBusProxy.cpp
)


set(PRJ_SRCS ${PRJ_LOCAL_SRCS} ${PRJ_TRIPCOMPUTER_SRCS} ${PRJ_STUB_GEN_SRCS} ${PRJ_PROXY_GEN_SRCS} ${PRJ_STUB_IMPL_SRCS})

include_directories(
    ${COMMONAPI_GEN_DIR}
    ${PRJ_SRC_GEN_DEMONSTRATOR_PATH}
    ${PRJ_SRC_GEN_NAVIGATION_PATH}
    ${PRJ_SRC_GEN_NAVIGATIONCORE_PATH}
    ${CMAKE_CURRENT_BINARY_DIR}
    ${TRIPCOMPUTER_DIR}
    ${DBUS_INCLUDE_DIRS}
    ${COMMONAPI_INCLUDE_DIRS}
    ${COMMONAPI_DBUS_INCLUDE_DIRS}
    ${GOBJECT_INCLUDE_DIRS}
    ${GLIB_INCLUDE_DIRS}
    ${DBUS_CPP_INCLUDE_DIRS}
    ${DBUS_CPP_GLIB_INCLUDE_DIRS}
)

link_directories(
    ${DBUS_LIBDIR}
    ${COMMONAPI_LIBDIR}
    ${COMMONAPI_DBUS_LIBDIR}
    ${GOBJECT_LIBRARY_DIRS}
    ${GLIB_LIBRARY_DIRS}
    ${DBUS_CPP_GLIB_DIRS}
)

set(LIBRARIES
    ${DBUS_LIBRARIES}
    ${COMMONAPI_LIBRARIES}
    ${COMMONAPI_DBUS_LIBRARIES}
    ${GOBJECT_LIBRARIES}
    ${GLIB_LIBRARIES}
    ${DBUS_CPP_GLIB_LIBRARIES}
)

add_executable(fuel-stop-advisor ${PRJ_SRCS})
target_link_libraries(fuel-stop-advisor ${LIBRARIES})

