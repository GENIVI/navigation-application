/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationRouteDescription.qml
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
			pixelSize:Constants.MENU_ROUTE_DESCRIPTION_TEXT_PIXEL_SIZE;
			text: "Back"
			page:"NavigationCalculatedRoute"
		}
	}

	DBusIf {
        id:dbusIf
    }

    Component.onCompleted: {
        var res=Genivi.routing_message_get(dbusIf,"GetRouteSegments",["int16",0,"array",["uint16",Genivi.NAVIGATIONCORE_DISTANCE,"uint16",Genivi.NAVIGATIONCORE_TIME,"uint16",Genivi.NAVIGATIONCORE_ROAD_NAME],"uint32",100,"uint32",0]);
        var array=res[3];
        var model=view.model;
        for (var i = 0 ; i < array.length ; i+=2) {
            if (array[i] == "map") {
                var map=array[i+1];
                var mapresult=Array;
                for (var j = 0 ; j < map.length ; j+=4) {
                    if (map[j] == 'uint16') {
                        mapresult[map[j+1]]=map[j+3][1];
                    }
                }
                var text=Genivi.distance(mapresult[Genivi.NAVIGATIONCORE_DISTANCE])+" "+Genivi.time(mapresult[Genivi.NAVIGATIONCORE_TIME])+" "+mapresult[Genivi.NAVIGATIONCORE_ROAD_NAME];
                model.append({"name":text});
            }
        }
    }
}
