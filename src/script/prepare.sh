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
TARGET_DIR=$PWD/../hmi/qml/Core

function usage
{
 echo "Usage: prepare -i input_directory"
 echo "       prepare -c clean images and style sheets"
 exit
}

# Get input directory from the command line
if [ $# -ge 1 ]; then
    if [ $1 = -h ]; then
	usage
    elif [ $1 = -i ]; then
 	shift
        input_dir=$1
    elif [ $1 = -c ]; then
	echo 'delete generated stuff'
 	rm -rf $TARGET_DIR/images/*.png
	rm -rf $TARGET_DIR/style-sheets/*-css.js
        exit
   else
        usage
    fi
else
    usage
fi

echo "Prepare the style sheet of fuel stop advisor"
./style_sheet_generator.sh -i $input_dir -o ../hmi/qml/Core/ -v -nl

