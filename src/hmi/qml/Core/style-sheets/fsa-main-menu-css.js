/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file fsa-main-menu-css.js
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

var select_navigation=new Object;
select_navigation[SOURCE]="Core/images/select-navigation.png";
select_navigation[X]=100;
select_navigation[Y]=30;
select_navigation[WIDTH]=140;
select_navigation[HEIGHT]=100;

var select_mapview=new Object;
select_mapview[SOURCE]="Core/images/select-mapview.png";
select_mapview[X]=560;
select_mapview[Y]=30;
select_mapview[WIDTH]=140;
select_mapview[HEIGHT]=100;

var select_trip=new Object;
select_trip[SOURCE]="Core/images/select-trip.png";
select_trip[X]=330;
select_trip[Y]=128;
select_trip[WIDTH]=140;
select_trip[HEIGHT]=100;

var select_poi=new Object;
select_poi[SOURCE]="Core/images/select-poi.png";
select_poi[X]=100;
select_poi[Y]=224;
select_poi[WIDTH]=140;
select_poi[HEIGHT]=100;

var select_configuration=new Object;
select_configuration[SOURCE]="Core/images/select-configuration.png";
select_configuration[X]=560;
select_configuration[Y]=224;
select_configuration[WIDTH]=140;
select_configuration[HEIGHT]=100;

var quit=new Object;
quit[SOURCE]="Core/images/quit.png";
quit[X]=600;
quit[Y]=374;
quit[WIDTH]=180;
quit[HEIGHT]=60;
quit[TEXTCOLOR]="black";
quit[PIXELSIZE]=38;
