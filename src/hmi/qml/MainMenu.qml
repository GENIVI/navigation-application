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
import QtQuick 1.0
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/fsa-main-menu-css.js" as StyleSheet;

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
        image:StyleSheet.fsa_main_menu_background[StyleSheet.SOURCE];
		anchors { fill: parent; topMargin: parent.headlineHeight}


        StdButton { source:StyleSheet.select_navigation[StyleSheet.SOURCE]; x:StyleSheet.select_navigation[StyleSheet.X]; y:StyleSheet.select_navigation[StyleSheet.Y]; width:StyleSheet.select_navigation[StyleSheet.WIDTH]; height:StyleSheet.select_navigation[StyleSheet.HEIGHT];
            id:navigation; page:"NavigationSearch"; explode:false; next:mapview; prev:quit}
        StdButton { source:StyleSheet.select_mapview[StyleSheet.SOURCE]; x:StyleSheet.select_mapview[StyleSheet.X]; y:StyleSheet.select_mapview[StyleSheet.Y]; width:StyleSheet.select_mapview[StyleSheet.WIDTH]; height:StyleSheet.select_mapview[StyleSheet.HEIGHT];
            id:mapview; explode:false; next:trip; prev:navigation; onClicked: {
				Genivi.data["mapback"]="MainMenu";
				Genivi.data["show_current_position"]=true;
				pageOpen("NavigationBrowseMap");
			}
		}
        StdButton { source:StyleSheet.select_trip[StyleSheet.SOURCE]; x:StyleSheet.select_trip[StyleSheet.X]; y:StyleSheet.select_trip[StyleSheet.Y]; width:StyleSheet.select_trip[StyleSheet.WIDTH]; height:StyleSheet.select_trip[StyleSheet.HEIGHT];
            id:trip; explode:false; next:poi; prev:mapview;onClicked: {
                pageOpen("TripComputer");
            }
        }
        StdButton { source:StyleSheet.select_poi[StyleSheet.SOURCE]; x:StyleSheet.select_poi[StyleSheet.X]; y:StyleSheet.select_poi[StyleSheet.Y]; width:StyleSheet.select_poi[StyleSheet.WIDTH]; height:StyleSheet.select_poi[StyleSheet.HEIGHT];
            id:poi; page:"POI"; explode:false; next:settings; prev:trip}
        StdButton { source:StyleSheet.select_configuration[StyleSheet.SOURCE]; x:StyleSheet.select_configuration[StyleSheet.X]; y:StyleSheet.select_configuration[StyleSheet.Y]; width:StyleSheet.select_configuration[StyleSheet.WIDTH]; height:StyleSheet.select_configuration[StyleSheet.HEIGHT];
            id:settings; page:"NavigationSettings"; explode:false; next:quit; prev:trip}
        StdButton { source:StyleSheet.quit[StyleSheet.SOURCE]; x:StyleSheet.quit[StyleSheet.X]; y:StyleSheet.quit[StyleSheet.Y]; width:StyleSheet.quit[StyleSheet.WIDTH]; height:StyleSheet.quit[StyleSheet.HEIGHT];textColor:StyleSheet.quitText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.quitText[StyleSheet.PIXELSIZE];
            id:quit; text: Genivi.gettext("Quit"); explode:false; next:navigation; prev:settings; onClicked:{dbusIf.quit()}}
    }
}
