/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file MainMenu.qml
*
* \brief This file is part of the navigation hmi.
*
* \author Martin Schaller <martin.schaller@it-schaller.de>
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
* 2014-03-05, Philippe Colliot, migration to the new HMI design
* <date>, <name>, <description of change>
*
* @licence end@
*/
import QtQuick 2.1
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/fsa-main-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    text: Genivi.gettext("MainMenu")
	next: navigation
    prev: navigation
    headlineFg: "grey"
    headlineBg: "blue"
    DBusIf {
		id:dbusIf;
	}

	HMIBgImage {
        image:StyleSheet.fsa_main_menu_background[Constants.SOURCE];
		anchors { fill: parent; topMargin: parent.headlineHeight}


        StdButton { source:StyleSheet.select_navigation[Constants.SOURCE]; x:StyleSheet.select_navigation[Constants.X]; y:StyleSheet.select_navigation[Constants.Y]; width:StyleSheet.select_navigation[Constants.WIDTH]; height:StyleSheet.select_navigation[Constants.HEIGHT];
            id:navigation; page:"NavigationSearch"; explode:false; next:mapview; prev:quit}
        StdButton { source:StyleSheet.select_mapview[Constants.SOURCE]; x:StyleSheet.select_mapview[Constants.X]; y:StyleSheet.select_mapview[Constants.Y]; width:StyleSheet.select_mapview[Constants.WIDTH]; height:StyleSheet.select_mapview[Constants.HEIGHT];
            id:mapview; explode:false; next:trip; prev:navigation; onClicked: {
				Genivi.data["mapback"]="MainMenu";
				Genivi.data["show_current_position"]=true;
				pageOpen("NavigationBrowseMap");
			}
		}
        StdButton { source:StyleSheet.select_trip[Constants.SOURCE]; x:StyleSheet.select_trip[Constants.X]; y:StyleSheet.select_trip[Constants.Y]; width:StyleSheet.select_trip[Constants.WIDTH]; height:StyleSheet.select_trip[Constants.HEIGHT];
            id:trip; explode:false; next:poi; prev:mapview;onClicked: {
                pageOpen("TripComputer");
            }
        }
        StdButton { source:StyleSheet.select_poi[Constants.SOURCE]; x:StyleSheet.select_poi[Constants.X]; y:StyleSheet.select_poi[Constants.Y]; width:StyleSheet.select_poi[Constants.WIDTH]; height:StyleSheet.select_poi[Constants.HEIGHT];
            id:poi; page:"POI"; explode:false; next:settings; prev:trip}
        StdButton { source:StyleSheet.select_configuration[Constants.SOURCE]; x:StyleSheet.select_configuration[Constants.X]; y:StyleSheet.select_configuration[Constants.Y]; width:StyleSheet.select_configuration[Constants.WIDTH]; height:StyleSheet.select_configuration[Constants.HEIGHT];
            id:settings; page:"NavigationSettings"; explode:false; next:quit; prev:trip}
        StdButton { source:StyleSheet.quit[Constants.SOURCE]; x:StyleSheet.quit[Constants.X]; y:StyleSheet.quit[Constants.Y]; width:StyleSheet.quit[Constants.WIDTH]; height:StyleSheet.quit[Constants.HEIGHT];textColor:StyleSheet.quitText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.quitText[Constants.PIXELSIZE];
            id:quit; text: Genivi.gettext("Quit"); explode:false; next:navigation; prev:settings; onClicked:{Qt.quit()}}
    }
}
