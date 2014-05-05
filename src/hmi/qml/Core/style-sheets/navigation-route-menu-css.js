/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file navigation-route-menu-css.js
*
* \brief This file is part of the navigation hmi.
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
*
* \version 1.1
*
* This Source Code Form is subject to the terms of the
* Mozilla Public License (MPL), v. 2.0.
* If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/.
*
* For further information see http://www.genivi.org/.
*
* List of changes:
* <date>, <name>, <description of change>
*
* @licence end@
*/
.pragma library
Qt.include("style-constants.js");

var locationTitle=new Object;
locationTitle[X]=52;
locationTitle[Y]=22;
locationTitle[TEXTCOLOR]="black";
locationTitle[PIXELSIZE]=25;
locationTitle[STYLECOLOR]="black";

var locationValue=new Object;
locationValue[X]=52;
locationValue[Y]=52;
locationValue[TEXTCOLOR]="white";
locationValue[PIXELSIZE]=32;
locationValue[STYLECOLOR]="white";
locationValue[WIDTH]=600;

var positionTitle=new Object;
positionTitle[X]=52;
positionTitle[Y]=116;
positionTitle[TEXTCOLOR]="black";
positionTitle[PIXELSIZE]=25;
positionTitle[STYLECOLOR]="black";

var positionValue=new Object;
positionValue[X]=52;
positionValue[Y]=150;
positionValue[TEXTCOLOR]="white";
positionValue[PIXELSIZE]=32;
positionValue[STYLECOLOR]="white";
positionValue[WIDTH]=600;

var destinationTitle=new Object;
destinationTitle[X]=52;
destinationTitle[Y]=210;
destinationTitle[TEXTCOLOR]="black";
destinationTitle[PIXELSIZE]=25;
destinationTitle[STYLECOLOR]="black";

var destinationValue=new Object;
destinationValue[X]=52;
destinationValue[Y]=244;
destinationValue[TEXTCOLOR]="white";
destinationValue[PIXELSIZE]=32;
destinationValue[STYLECOLOR]="white";
destinationValue[WIDTH]=600;

var show_location_on_map=new Object;
show_location_on_map[SOURCE]="Core/images/show-location-on-map.png";
show_location_on_map[X]=660;
show_location_on_map[Y]=38;
show_location_on_map[WIDTH]=100;
show_location_on_map[HEIGHT]=60;

var set_as_position=new Object;
set_as_position[SOURCE]="Core/images/set-as-position.png";
set_as_position[X]=660;
set_as_position[Y]=142;
set_as_position[WIDTH]=100;
set_as_position[HEIGHT]=60;

var set_as_destination=new Object;
set_as_destination[SOURCE]="Core/images/set-as-destination.png";
set_as_destination[X]=660;
set_as_destination[Y]=246;
set_as_destination[WIDTH]=100;
set_as_destination[HEIGHT]=60;

var route=new Object;
route[SOURCE]="Core/images/route.png";
route[X]=20;
route[Y]=374;
route[WIDTH]=180;
route[HEIGHT]=60;
route[TEXTCOLOR]="black";
route[PIXELSIZE]=38;

var calculate_curr=new Object;
calculate_curr[SOURCE]="Core/images/route.png";
calculate_curr[X]=224;
calculate_curr[Y]=374;
calculate_curr[WIDTH]=180;
calculate_curr[HEIGHT]=60;
calculate_curr[TEXTCOLOR]="black";
calculate_curr[PIXELSIZE]=38;

var back=new Object;
back[SOURCE]="Core/images/route.png";
back[X]=600;
back[Y]=374;
back[WIDTH]=180;
back[HEIGHT]=60;
back[TEXTCOLOR]="black";
back[PIXELSIZE]=38;
