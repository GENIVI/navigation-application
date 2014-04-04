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
import QtQuick 1.0
import "Core"
import "Core/genivi.js" as Genivi;

HMIMenu {
	id: menu
    headlineFg: "grey"
    headlineBg: "blue"
    text: Genivi.gettext("NavigationManeuversList")

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
			page:"NavigationBrowseMap";
		}
	}
	DBusIf {
                id:dbusIf
		Component.onCompleted: {
            var res=Genivi.guidance_message_get(dbusIf,"GetManeuversList",["uint16",0xffff,"uint32",0]);
			if (res[0] == "uint16" && res[2] == "array") {
				var array=res[3];
                var model=view.model;
                for (var i = 0 ; i < array.length ; i+=2) {
                    if (array[i] == "structure" && array[i+1][0] == "string" && array[i+1][2] == "string" && array[i+1][4] == "uint16" && array[i+1][6] == "uint16" && array[i+1][8] == "uint32" && array[i+1][10] == "array") {
                        var structure=array[i+1];
                        var subarray=structure[11];
                        for (var j = 0 ; j < subarray.length ; j+=2) {
                            //multiple maneuvers are not managed !
                            if (subarray[j] == "structure" && subarray[j+1][0] == "uint32" && subarray[j+1][2] == "uint32" && subarray[j+1][4] == "int32" && subarray[j+1][6] == "structure" && subarray[j+1][8] == "structure") {
                                var substructure=subarray[j+1];
                                if (substructure[7][0] == "uint16" && substructure[7][2] == "uint16" && substructure[9][0] == "uint16" && substructure[9][2] == "string") {
                                    var text=Genivi.distance(substructure[1])+" "+Genivi.distance(structure[9])+" "+Genivi.ManeuverType[substructure[7][1]]+":"+Genivi.ManeuverDirection[substructure[9][1]]+" "+structure[3];
                                    model.append({"name":text});
                                }
                            }
                        }
					}
				}
			} else {
				Console.log("Unexpected result from GetManeuversList");
				Genivi.dump("",res);
			}
        }
        }
}
