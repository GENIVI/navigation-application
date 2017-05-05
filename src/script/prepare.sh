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
BASH_DIR=$(dirname "${BASH_SOURCE[0]}")
TARGET_DIR=$BASH_DIR/../hmi
STYLE_SHEETS_GENERATED_INDICATOR=$TARGET_DIR/style-sheets/the-style-sheets-have-been-generated-css.js

function usage
{
 echo "Usage: prepare -i input_directory"
 echo 'Generate a new set of style sheet'
 exit
}

if [ $# -ge 1 ]; then
    if [ $1 = -h ]; then
	usage
    elif [ $1 = -i ]; then
	# Get input directory from the command line
 	shift
        input_dir=$1
   else
        usage
    fi
else
    usage
fi

echo 'Delete the current style sheet'
rm -rf $TARGET_DIR/images/*.png
rm -rf $TARGET_DIR/style-sheets/*-css.js

echo "Prepare the style sheet of fuel stop advisor"
$TARGET_DIR/style_sheet_generator.sh -i $input_dir -o $TARGET_DIR -v -nl

echo "Create the empty file as an indicator"
touch $STYLE_SHEETS_GENERATED_INDICATOR


