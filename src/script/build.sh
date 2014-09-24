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
TOP_BIN_DIR=$TOP_DIR/bin

#include common settings
source fsa-config.sh

GENIVI_NAVIGATION_ROUTING_API=$NAVIGATION_SERVICE_API_DIR/navigation-core/genivi-navigationcore-routing.xml
GENIVI_NAVIGATION_CONSTANTS_API=$NAVIGATION_SERVICE_API_DIR/navigation-core/genivi-navigationcore-constants.xml

#--------------------------------------------------------------------------
# Compiler Flags
#--------------------------------------------------------------------------
# modify the following flags as needed:
#--------------------------------------------------------------------------

usage() {
    echo "Usage: ./build.sh Build fuel stop advisor"
    echo "   or: ./build.sh [command]"
    echo
    echo "command:"
    echo "  make            Build"
    echo "  clean           Clean"
    echo "  src-clean       Clean the cloned sources"
    echo "  help            Print Help"
    echo
    echo
}

build() {
    echo ''
    echo 'Building fuel stop advisor'

    cd $TOP_DIR 
    mkdir -p bin
    cd $TOP_BIN_DIR
    cmake $TOP_DIR

    cd $TOP_BIN_DIR
	mkdir -p $NAVIGATION_SERVICE
    cd $NAVIGATION_SERVICE_BUILD_SCRIPT_DIR 
	# call the bash script of navigation, set the bin dir to navigation-service and tell it where to clone the positioning
	bash ./build.sh make $NAVIGATION_SERVICE_BIN_DIR $POSITIONING_SRC_DIR	

    cd $TOP_BIN_DIR 
    mkdir -p $FUEL_STOP_ADVISOR
    cd $FUEL_STOP_ADVISOR_BIN_DIR
    cmake -Dgenivi-navigationcore-routing_API=$GENIVI_NAVIGATION_ROUTING_API -Dgenivi-navigationcore-constants_API=$GENIVI_NAVIGATION_CONSTANTS_API $FUEL_STOP_ADVISOR_SRC_DIR && make

    cd $TOP_BIN_DIR 
    mkdir -p $AUTOMOTIVE_MESSAGE_BROKER
    cd $AUTOMOTIVE_MESSAGE_BROKER_BIN_DIR
    cmake $AUTOMOTIVE_MESSAGE_BROKER_SRC_DIR && make

    cd $TOP_BIN_DIR 
    mkdir -p $LOG_REPLAYER
    cd $LOG_REPLAYER_BIN_DIR
    cmake $LOG_REPLAYER_SRC_DIR && make

    cd $TOP_BIN_DIR 
    mkdir -p $GENIVI_LOGREPLAYER
    cd $GENIVI_LOGREPLAYER_BIN_DIR
    cmake -Dautomotive-message-broker_SRC=$AUTOMOTIVE_MESSAGE_BROKER_SRC_DIR -Dautomotive-message-broker_BIN=$AUTOMOTIVE_MESSAGE_BROKER_BIN_DIR $GENIVI_LOGREPLAYER_SRC_DIR && make

    cd $TOP_BIN_DIR 
    mkdir -p $HMI_LAUNCHER
    cd $HMI_LAUNCHER_BIN_DIR
    cmake -Dnavigation-service_API=$NAVIGATION_SERVICE_API_DIR -Dpositioning_API=$ENHANCED_POSITION_SERVICE_API_DIR $HMI_LAUNCHER_SRC_DIR && make

    cd $TOP_BIN_DIR 
    mkdir -p $POI_SERVER
    cd $POI_SERVER_BIN_DIR
    cmake -Dpositioning_SRC_DIR=$POSITIONING_SRC_DIR $POI_SERVER_SRC_DIR && make

}

clean() {
    echo ''
    echo 'Clean all'
    rm -rf $TOP_BIN_DIR
}

src-clean() {
    echo ''
    echo 'Clean cloned stuff'
    rm -rf $POSITIONING_SRC_DIR
    rm -rf $NAVIGATION_SERVICE_SRC_DIR
    rm -rf $AUTOMOTIVE_MESSAGE_BROKER_SRC_DIR
	clean
}

if [ $# -ge 1 ]; then
    if [ $1 = help ]; then
        usage
    elif [ $1 = make ]; then
        build
    elif [ $1 = clean ]; then
        clean
    elif [ $1 = src-clean ]; then
        src-clean
    else
        usage
    fi
elif [ $# -eq 0 ]; then
    build
else
    usage
fi

