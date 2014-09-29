#!/bin/bash

###########################################################################
# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# Component Name: fuel stop advisor application
# Author: Kang-Joon VERNIERS <kang-joon.verniers@awtce.be>
#
# Copyright (C) 2014, AISIN AW CO.
# 
# License:
# This Source Code Form is subject to the terms of the
# Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
# this file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# @licence end@
###########################################################################

function usage
{
 echo "Usage: style_sheet_generator -i input_directory -o output_directory -v|-nv -l|-nl"
 echo "this style sheet generator requires Gimp and the generate_style_sheet.py plug-in to be installed"
 echo $'\t' "-v: selects visible layers=TRUE"
 echo $'\t' "-nv: selects visible layers=FALSE"
 echo $'\t' "-l: generate xml log=TRUE"
 echo $'\t' "-nl: generate xml log=FALSE"
}

# Get input and output directories from the command line

if [ $# != 6 -a $# != 3 -a $# != 1 ]; then
 usage
 exit 1
fi

while [ "$1" != "" ]; do
 case $1 in
   -i ) shift
        input_dir=$1
        ;;
   -o ) shift
        output_dir=$1
        ;;
   -h ) usage
        exit
        ;;
   -v ) select_visible_layers=TRUE
        ;;
   -nv ) select_visible_layers=FALSE
        ;;
   -l ) generate_xml_log=TRUE
        ;;
   -nl ) generate_xml_log=FALSE
        ;;
   * )  usage
        exit 1
 esac
 shift
done

echo "style_sheet_generator"
echo $'\t' "Input directory : " $input_dir
echo $'\t' "Output directory: " $output_dir
echo $'\t' "select_visible_layers: " $select_visible_layers
echo $'\t' "generate_xml_log: " $generate_xml_log

echo 
# Main processing, using Gimp and the generate_style_sheet.py plug-in
{
cat <<EOF
(define (do-generate-style-sheet filename outputdir select_visible_layers generate_xml_log)
 (let* (
  (image (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
  (drawable (car (gimp-image-get-active-layer image)))
  )
 (python-fu-generate-style-sheet RUN-NONINTERACTIVE image drawable select_visible_layers outputdir generate_xml_log)
 (gimp-image-delete image)   
 )
)
(gimp-message-set-handler 1) ;
EOF

for file in $input_dir/*.xcf; do
   echo "(gimp-message \"$file\")"
   echo "(do-generate-style-sheet \"$file\" \"$output_dir\" $select_visible_layers $generate_xml_log)"
done

echo "(gimp-quit 0)"
} | {
gimp -i -b - 
}

