/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationSearchHistory.qml
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
* 2014-03-05, Philippe Colliot, creation of the new page
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

    DBusIf {
        id:dbusIf
    }

	Column {
                id:content
                anchors { fill: parent; topMargin: menu.hspc/2 }
	
		Component {
			id: listDelegate
			Text {
                property real index:number;
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
            id:view
            property real selectedEntry
			height:parent.height-back.height;
			width:parent.width;
			delegate: listDelegate
			next:back
			prev:back
            onSelected:{
                Genivi.data['description'] = what.text;
                Genivi.data['lat'] = Genivi.historyOfLastEnteredLat[what.index];
                Genivi.data['lon'] = Genivi.historyOfLastEnteredLon[what.index];
                pageOpen("NavigationRoute");
            }
        }
		StdButton {
			id:back
			text: "Back"
            page:"NavigationSearch"
		}
	}
    Component.onCompleted: {
        var model=view.model;
        var array=Genivi.historyOfLastEnteredLocation;
        Genivi.dump("",array.length);
        // display list of locations (fifo)
        var i = Genivi.historyOfLastEnteredLocationOut;
        while (i !== Genivi.historyOfLastEnteredLocationIn)
        {
            model.append({"name":Genivi.historyOfLastEnteredLocation[i],"number":(i)});
            if ((i+1) >= Genivi.historyOfLastEnteredLocationDepth)
                i=0;
            else
                i+=1;
        };
        view.forceActiveFocus();
    }
}
