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
cmake_minimum_required(VERSION 2.8)
set (git_get_src_version git rev-parse HEAD)
set (git_executable git)
set (create_file cmake -E touch)

# Check if navigation-service stuff with the right version has been cloned and do it if necessary
set(navigation-service_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/navigation-service)
set(navigation-service_URL http://git.projects.genivi.org/lbs/navigation.git)
set(navigation-service_VERSION fb92406d88997bd20c89b094b50db8762e1a4869)

if (EXISTS ${navigation-service_SRC_DIR})
	execute_process(	
		COMMAND ${git_get_src_version}  
		WORKING_DIRECTORY "${navigation-service_SRC_DIR}"
		RESULT_VARIABLE result
		OUTPUT_VARIABLE version
	)
	if (${version} MATCHES ${navigation-service_VERSION})
		message(STATUS "version of navigation-service up to date")	
	else()
		message(STATUS "get the right version")
	 	execute_process(
			COMMAND "${git_executable}" checkout ${navigation-service_VERSION}
			WORKING_DIRECTORY "${navigation-service_SRC_DIR}"
			RESULT_VARIABLE error_code
		)
		if(error_code)
			message(FATAL_ERROR "Failed to checkout version: '${navigation-service_VERSION}'")
		endif()	
	endif()
else()
	message(STATUS "clone navigation-service")
	execute_process(
		COMMAND "${git_executable}" clone "${navigation-service_URL}" "${navigation-service_SRC_DIR}"
		RESULT_VARIABLE error_code
	)
 	if(error_code)
		message(FATAL_ERROR "Failed to clone repository: '${navigation-service_URL}'")
	endif()

	message(STATUS "get the right version")
 	execute_process(
		COMMAND "${git_executable}" checkout ${navigation-service_VERSION}
		WORKING_DIRECTORY "${navigation-service_SRC_DIR}"
		RESULT_VARIABLE error_code
	)
	if(error_code)
		message(FATAL_ERROR "Failed to checkout version: '${navigation-service_VERSION}'")
	endif()	
endif()

# Check if automotive-message-broker stuff with the right version has been cloned and do it if necessary
set(automotive-message-broker_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/automotive-message-broker)
set(automotive-message-broker_URL https://github.com/otcshare/automotive-message-broker.git)
set(automotive-message-broker_VERSION ac3fe53327a13afc571efe079a31a0472ea285a3)
set(automotive-message-broker_PATCH_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/patches)
set(automotive-message-broker_PATCH_DUMMY_FILE ${automotive-message-broker_SRC_DIR}/.patched)

if (EXISTS ${automotive-message-broker_SRC_DIR})
	execute_process(	
		COMMAND ${git_get_src_version}  
		WORKING_DIRECTORY "${automotive-message-broker_SRC_DIR}"
		RESULT_VARIABLE result
		OUTPUT_VARIABLE version
	)
	if (${version} MATCHES ${automotive-message-broker_VERSION})
		message(STATUS "version of automotive-message-broker up to date")	
	else()
		message(STATUS "get the right version")
	 	execute_process(
			COMMAND "${git_executable}" checkout ${automotive-message-broker_VERSION}
			WORKING_DIRECTORY "${automotive-message-broker_SRC_DIR}"
			RESULT_VARIABLE error_code
		)
		if(error_code)
			message(FATAL_ERROR "Failed to checkout version: '${automotive-message-broker_VERSION}'")
		endif()	
	endif()
else()
	message(STATUS "clone automotive-message-broker")
	execute_process(
		COMMAND "${git_executable}" clone "${automotive-message-broker_URL}" "${automotive-message-broker_SRC_DIR}"
		RESULT_VARIABLE error_code
	)
 	if(error_code)
		message(FATAL_ERROR "Failed to clone repository: '${automotive-message-broker_URL}'")
	endif()
	message(STATUS "get the right version")
 	execute_process(
		COMMAND "${git_executable}" checkout ${automotive-message-broker_VERSION}
		WORKING_DIRECTORY "${automotive-message-broker_SRC_DIR}"
		RESULT_VARIABLE error_code
	)
	if(error_code)
		message(FATAL_ERROR "Failed to checkout version: '${automotive-message-broker_VERSION}'")
	endif()	
endif()

if (EXISTS ${automotive-message-broker_PATCH_DUMMY_FILE})
	message(STATUS "patch already applied")
else()
	message(STATUS "apply the patch")
	execute_process(
		COMMAND patch -d ${automotive-message-broker_SRC_DIR} -p1 -s <${automotive-message-broker_PATCH_SRC_DIR}/amb_allow_sessionbus.patch
		COMMAND ${create_file} ${automotive-message-broker_PATCH_DUMMY_FILE}
		TIMEOUT 0.1 #cmake -E touch never ends so add a timeout here
		WORKING_DIRECTORY "${automotive-message-broker_SRC_DIR}"
		RESULT_VARIABLE error_code
	)
endif()


