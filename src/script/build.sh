#!/bin/bash

###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: fuel stop advisor application
# Author: Philippe Colliot <philippe.colliot@mpsa.com>
#
# Copyright (C) 2013-2014, PCA Peugeot Citroen
# 
# License:
# This Source Code Form is subject to the terms of the
# Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
# this file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# @licence end@
###########################################################################
TOP_DIR=$PWD/..
TOP_BIN_DIR=$TOP_DIR/../bin

#include common settings
source fsa-config.sh

# by default no ilm 
lm=0

# by default no debug
dbg=0


#--------------------------------------------------------------------------
# Compiler Flags
#--------------------------------------------------------------------------
# modify the following flags as needed:
#--------------------------------------------------------------------------

usage() {
    echo "Usage: ./build.sh [command]"
    echo
    echo "command:"
    echo "  make            Build"
    echo "  makelm          Build with layer manager"
    echo "  maked           Build in debug mode"
    echo "  clean           Clean the bin"
    echo "  src-clean       Clean the cloned sources and the bin"
    echo "  clone           Clone the sources"
    echo "  help            Print Help"
    echo
    echo
}

clone() {
    echo ''
    echo 'Clone/update version of additional sources if needed'

    cd $TOP_DIR/.. 
    mkdir -p bin
    cd $TOP_BIN_DIR
    cmake $TOP_DIR
 
    cd $TOP_BIN_DIR
	mkdir -p $NAVIGATION_SERVICE
    cd $NAVIGATION_SERVICE_BUILD_SCRIPT_DIR 
	# call the bash script of navigation, set the bin dir to navigation-service and tell it where to clone the positioning and the ilm
	bash ./build.sh clone $NAVIGATION_SERVICE_BIN_DIR $POSITIONING_SRC_DIR $IVI_LAYER_MANAGER_SRC_DIR
}

build() {

    echo ''
    echo 'Building fuel stop advisor'

    cd $TOP_DIR/.. 
    mkdir -p bin

    cd $TOP_BIN_DIR
	mkdir -p $NAVIGATION_SERVICE

	# Build the navigation service (including DBus files generation)
    cd $NAVIGATION_SERVICE_BUILD_SCRIPT_DIR 
	if [ $lm -eq 0 ]; then
		if [ $dbg -eq 0 ]; then
			bash ./build.sh make $NAVIGATION_SERVICE_BIN_DIR $POSITIONING_SRC_DIR $IVI_LAYER_MANAGER_SRC_DIR
		else
			bash ./build.sh maked $NAVIGATION_SERVICE_BIN_DIR $POSITIONING_SRC_DIR $IVI_LAYER_MANAGER_SRC_DIR
		fi
	else
			bash ./build.sh makelm $NAVIGATION_SERVICE_BIN_DIR $POSITIONING_SRC_DIR $IVI_LAYER_MANAGER_SRC_DIR
	fi
    cd $TOP_BIN_DIR 
    mkdir -p $FUEL_STOP_ADVISOR
    cd $FUEL_STOP_ADVISOR_BIN_DIR
    cmake -Dgenerated_api_DIR=$GENERATED_API_DIR $FUEL_STOP_ADVISOR_FLAGS $FUEL_STOP_ADVISOR_SRC_DIR && make

    cd $TOP_BIN_DIR 
    mkdir -p $AUTOMOTIVE_MESSAGE_BROKER
    cd $AUTOMOTIVE_MESSAGE_BROKER_BIN_DIR
    cmake $AUTOMOTIVE_MESSAGE_BROKER_SRC_DIR && make
	sudo make install

    cd $TOP_BIN_DIR 
    mkdir -p $LOG_REPLAYER
    cd $LOG_REPLAYER_BIN_DIR
    cmake $FUEL_STOP_ADVISOR_FLAGS $LOG_REPLAYER_SRC_DIR && make

    cd $TOP_BIN_DIR 
    mkdir -p $GENIVI_LOGREPLAYER
    cd $GENIVI_LOGREPLAYER_BIN_DIR
    cmake -Dautomotive-message-broker_SRC=$AUTOMOTIVE_MESSAGE_BROKER_SRC_DIR -Dautomotive-message-broker_BIN=$AUTOMOTIVE_MESSAGE_BROKER_BIN_DIR $GENIVI_LOGREPLAYER_SRC_DIR && make

    cd $TOP_BIN_DIR 
    mkdir -p $HMI_LAUNCHER
    cd $HMI_LAUNCHER_BIN_DIR
    cmake -DLM=$lm -Dnavigation-service_API=$NAVIGATION_SERVICE_API_DIR -Dpositioning_API=$ENHANCED_POSITION_SERVICE_API_DIR -Dfuel-stop-advisor_API=$FUEL_STOP_ADVISOR_SRC_DIR $HMI_LAUNCHER_SRC_DIR && make

    cd $TOP_BIN_DIR 
    mkdir -p $POI_SERVER
    cd $POI_SERVER_BIN_DIR
    cmake -Dapi_DIR=$NAVIGATION_SERVICE_API_DIR -Dpositioning_API=$ENHANCED_POSITION_SERVICE_API_DIR -Dgenerated_api_DIR=$GENERATED_API_DIR $POI_SERVER_SRC_DIR && make

}

clean() {
	echo 'delete' $TOP_BIN_DIR 
    rm -rf $TOP_BIN_DIR
}

src-clean() {
	echo 'delete' $POSITIONING_SRC_DIR 
    rm -rf $POSITIONING_SRC_DIR
	echo 'delete' $NAVIGATION_SERVICE_SRC_DIR 
    rm -rf $NAVIGATION_SERVICE_SRC_DIR
	echo 'delete' $AUTOMOTIVE_MESSAGE_BROKER_SRC_DIR 
    rm -rf $AUTOMOTIVE_MESSAGE_BROKER_SRC_DIR
	clean
}

if [ $# -ge 1 ]; then
    if [ $1 = help ]; then
        usage
    elif [ $1 = make ]; then
		FUEL_STOP_ADVISOR_FLAGS='-DWITH_DEBUG=OFF'
        build
    elif [ $1 = makelm ]; then
		FUEL_STOP_ADVISOR_FLAGS='-DWITH_DEBUG=OFF'
        lm=1
        build
    elif [ $1 = maked ]; then
		FUEL_STOP_ADVISOR_FLAGS='-DWITH_DEBUG=ON'
		dbg=1
        build
    elif [ $1 = clean ]; then
        clean
    elif [ $1 = src-clean ]; then
        src-clean
    elif [ $1 = clone ]; then
        clone
    else
        usage
    fi
else
    usage
fi

