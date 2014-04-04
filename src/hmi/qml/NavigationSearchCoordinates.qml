/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationSearchCoordinates.qml
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
    text: Genivi.gettext("NavigationSearchCoordinates")
	property string pagefile:"NavigationSearchCoordinates"

	function accept(what)
        {
		if (what == latitude) {
			longitude.take_focus();
		}
	}

	function leave()
	{
	}


    HMIBgImage {
        image:"navigation-search-by-coordinates-menu-background";
        anchors { fill: parent; topMargin: parent.headlineHeight}
        //Important notice: x,y coordinates from the left/top origin of the component
        //so take in account the header height and substract it


        Text {
                height:menu.hspc
                x:100; y:30;
                font.pixelSize: 25;
                style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true;
                text: Genivi.gettext("Latitude");
        }
        EntryField {
            x:100; y:74; width:380; height:60;
            id: latitude
			globaldata: 'lat'
			textfocus: true
			next: longitude
			prev: back
			onLeave:{menu.leave(0)}
		}
        Text {
                height:menu.hspc
                x:100; y:180;
                font.pixelSize: 25;
                style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true;
                text: Genivi.gettext("Longitude");
        }
		EntryField {
            x:100; y:224; width:380; height:60;
            id: longitude
			globaldata: 'lon'
			next: ok
			prev: latitude
			onLeave:{menu.leave(0)}
		}
        StdButton {
            textColor:"black";
            pixelSize:38 ;
            source:"Core/images/ok.png";
            x:20; y:374; width:180; height:60;
            id:ok
            next:back
            prev:longitude
            text:Genivi.gettext("Ok")
            disabled: true
            onClicked:{
                Genivi.data['lat']=latitude.text;
                Genivi.data['lon']=longitude.text;
                Genivi.data['description']="Latitude "+latitude.text+"° Longitude "+longitude.text+"°";
                pageOpen("NavigationRoute");
            }
        }
        StdButton { textColor:"black"; pixelSize:38 ;source:"Core/images/back.png"; x:600; y:374; width:180; height:60;id:back; text: Genivi.gettext("Back"); explode:false; next:latitude; prev:ok;
            onClicked:{
                Genivi.data['lat']='';
                Genivi.data['lon']='';
                pageOpen("NavigationSearch");
            }
        }
    }
}
