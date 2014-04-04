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
		image:"fsa-main-menu-background";
		anchors { fill: parent; topMargin: parent.headlineHeight}
        //Important notice: x,y coordinates from the left/top origin of the component
        //so take in account the header height and substract it


        StdButton { source:"Core/images/select-navigation.png"; x:100; y:30; width:140; height:100;id:navigation; page:"NavigationSearch"; explode:false; next:mapview; prev:quit}
        StdButton { source:"Core/images/select-mapview.png"; x:560; y:30; width:140; height:100;id:mapview; explode:false; next:trip; prev:navigation; onClicked: {
				Genivi.data["mapback"]="MainMenu";
				Genivi.data["show_current_position"]=true;
				pageOpen("NavigationBrowseMap");
			}
		}
        StdButton { source:"Core/images/select-trip.png"; x:330; y:128; width:140; height:100;id:trip; explode:false; next:poi; prev:mapview;onClicked: {
                pageOpen("TripComputer");
            }
        }
        StdButton { source:"Core/images/select-poi.png"; x:100; y:224; width:140; height:100;id:poi; page:"POI"; explode:false; next:settings; prev:trip}
        StdButton { source:"Core/images/select-configuration.png"; x:560; y:224; width:140; height:100;id:settings; page:"NavigationSettings"; explode:false; next:quit; prev:trip}
        StdButton { textColor:"black"; pixelSize:38 ;source:"Core/images/quit.png"; x:600; y:374; width:180; height:60;id:quit; text: Genivi.gettext("Quit"); explode:false; next:navigation; prev:settings; onClicked:{dbusIf.quit()}}
    }
}
