/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file resource.js.in
*
* \brief This file is part of the navigation hmi.
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
*
* \version 1.0
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

Qt.include("/home/psa/Desktop/genivi/navigation-application-master/src/build/hmi/qml/hmi-launcher/constants.js");

var IconPath = "/home/psa/Desktop/genivi/navigation-application-master/src/build/navigation/navit/navit/xpm/"

var ManeuverTypeIcon = new Object;
ManeuverTypeIcon[NAVIGATIONCORE_INVALID]=IconPath+"unknown_64_64.png";
ManeuverTypeIcon[NAVIGATIONCORE_STRAIGHT_ON]=IconPath+"nav_straight_bk.png";
ManeuverTypeIcon[NAVIGATIONCORE_CROSSROAD]=IconPath+"unknown_64_64.png";
ManeuverTypeIcon[NAVIGATIONCORE_ROUNDABOUT]=IconPath+"nav_roundabout_l1_bk.png";
ManeuverTypeIcon[NAVIGATIONCORE_HIGHWAY_ENTER]=IconPath+"nav_merge_left_bk.png";
ManeuverTypeIcon[NAVIGATIONCORE_HIGHWAY_EXIT]=IconPath+"nav_exit_right_bk.png";
ManeuverTypeIcon[NAVIGATIONCORE_FOLLOW_SPECIFIC_LANE]=IconPath+"unknown_64_64.png";
ManeuverTypeIcon[NAVIGATIONCORE_DESTINATION]=IconPath+"nav_destination_bk.png";
ManeuverTypeIcon[NAVIGATIONCORE_WAYPOINT]=IconPath+"unknown_64_64.png";

var ManeuverDirectionIcon = new Object;
ManeuverDirectionIcon[NAVIGATIONCORE_INVALID]=IconPath+"nav_straight_wh.png";
ManeuverDirectionIcon[NAVIGATIONCORE_STRAIGHT_ON]=IconPath+"nav_straight_bk.png";
ManeuverDirectionIcon[NAVIGATIONCORE_LEFT]=IconPath+"nav_left_1_bk.png";
ManeuverDirectionIcon[NAVIGATIONCORE_SLIGHT_LEFT]=IconPath+"nav_left_2_bk.png";
ManeuverDirectionIcon[NAVIGATIONCORE_HARD_LEFT]=IconPath+"nav_left_3_bk.png";
ManeuverDirectionIcon[NAVIGATIONCORE_RIGHT]=IconPath+"nav_right_1_bk.png";
ManeuverDirectionIcon[NAVIGATIONCORE_SLIGHT_RIGHT]=IconPath+"nav_right_2_bk.png";
ManeuverDirectionIcon[NAVIGATIONCORE_HARD_RIGHT]=IconPath+"nav_right_3_bk.png";
ManeuverDirectionIcon[NAVIGATIONCORE_UTURN_RIGHT]=IconPath+"nav_turnaround_right_bk.png";
ManeuverDirectionIcon[NAVIGATIONCORE_UTURN_LEFT]=IconPath+"nav_turnaround_left_bk.png";

