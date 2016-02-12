/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationManeuversList.qml
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
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    property string pagefile:"NavigationManeuversList"

	Column {
                id:content
                anchors { fill: parent; topMargin: menu.hspc/2 }
	
		Component {
			id: listDelegate
			Text {
				width: 180;
				height: 20;
				id:text;
				text: name;
				font.pixelSize: 20;
				style: Text.Sunken;
				color: "white";
				styleColor: "black";
				smooth: true
			}
		}

		HMIList {
			property real selectedEntry
			height:parent.height-back.height;
			width:parent.width;
			id:view
			delegate: listDelegate
			next:back
			prev:back
		}
		StdButton {
			id:back
			text: "Back"
			pixelSize:Constants.MENU_ROUTE_DESCRIPTION_TEXT_PIXEL_SIZE;
            onClicked:{leaveMenu();}
		}
	}

    DBusIf {
        id:dbusIf
    }

    Component.onCompleted: {
        var res=Genivi.guidance_GetManeuversList(dbusIf,0xffff,0);
        var maneuversList=res[3];
        var model=view.model;
        for (var i = 0 ; i < maneuversList.length ; i+=2) {
            var roadNameAfterManeuver=maneuversList[i+1][3];
            var offsetOfNextManeuver=maneuversList[i+1][9];
            var items=maneuversList[i+1][11];

            for (var j = 0 ; j < items.length ; j+=2) {
                //multiple maneuvers are not managed !
                var offsetOfManeuver=items[j+1][1];
                var direction=items[j+1][5];
                var maneuver=items[j+1][7];
                var maneuverData=items[j+1][9];
                if (maneuverData[1] == Genivi.NAVIGATIONCORE_DIRECTION)
                {
                   var text=Genivi.distance(offsetOfManeuver)+" "+Genivi.distance(offsetOfNextManeuver)+" "+Genivi.ManeuverType[maneuver]+":"+Genivi.ManeuverDirection[direction]+" "+roadNameAfterManeuver;
                   model.append({"name":text});
                }
            }
        }
    }
}
