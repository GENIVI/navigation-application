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
import "Core/style-sheets/navigation-search-coordinates-menu-css.js" as StyleSheet;

HMIMenu {
	id: menu
    headlineFg: "grey"
    headlineBg: "blue"
    text: Genivi.gettext("NavigationSearchCoordinates")
	property string pagefile:"NavigationSearchCoordinates"

	function accept(what)
        {
        if (what == latitudeValue) {
            longitudeValue.take_focus();
		}
	}

	function leave()
	{
	}


    HMIBgImage {
        image:StyleSheet.navigation_search_by_coordinates_menu_background[StyleSheet.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

        Text {
            x:StyleSheet.latitudeTitle[StyleSheet.X]; y:StyleSheet.latitudeTitle[StyleSheet.Y]; width:StyleSheet.latitudeTitle[StyleSheet.WIDTH]; height:StyleSheet.latitudeTitle[StyleSheet.HEIGHT];color:StyleSheet.latitudeTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.latitudeTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.latitudeTitle[StyleSheet.PIXELSIZE];
            id:latitudeTitle;
            style: Text.Sunken;
            smooth: true;
            text: Genivi.gettext("Latitude");
        }
        EntryField {
            x:StyleSheet.latitudeValue[StyleSheet.X]; y:StyleSheet.latitudeValue[StyleSheet.Y]; width: StyleSheet.latitudeValue[StyleSheet.WIDTH]; height: StyleSheet.latitudeValue[StyleSheet.HEIGHT];
            id: latitudeValue
			globaldata: 'lat'
			textfocus: true
            next: longitudeValue
			prev: back
			onLeave:{menu.leave(0)}
		}
        Text {
            x:StyleSheet.longitudeTitle[StyleSheet.X]; y:StyleSheet.longitudeTitle[StyleSheet.Y]; width:StyleSheet.longitudeTitle[StyleSheet.WIDTH]; height:StyleSheet.longitudeTitle[StyleSheet.HEIGHT];color:StyleSheet.longitudeTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.longitudeTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.longitudeTitle[StyleSheet.PIXELSIZE];
            id:longitudeTitle;
            style: Text.Sunken;
            smooth: true;
            text: Genivi.gettext("Longitude");
        }
		EntryField {
            x:StyleSheet.longitudeValue[StyleSheet.X]; y:StyleSheet.longitudeValue[StyleSheet.Y]; width: StyleSheet.longitudeValue[StyleSheet.WIDTH]; height: StyleSheet.longitudeValue[StyleSheet.HEIGHT];
            id: longitudeValue
			globaldata: 'lon'
			next: ok
            prev: latitudeValue
			onLeave:{menu.leave(0)}
		}
        StdButton {
            source:StyleSheet.ok[StyleSheet.SOURCE]; x:StyleSheet.ok[StyleSheet.X]; y:StyleSheet.ok[StyleSheet.Y]; width:StyleSheet.ok[StyleSheet.WIDTH]; height:StyleSheet.ok[StyleSheet.HEIGHT];textColor:StyleSheet.okText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.okText[StyleSheet.PIXELSIZE];
            id:ok
            next:back
            prev:longitudeValue
            text:Genivi.gettext("Ok")
            disabled: true
            onClicked:{
                Genivi.data['lat']=latitudeValue.text;
                Genivi.data['lon']=longitudeValue.text;
                Genivi.data['description']="Latitude "+latitudeValue.text+"° Longitude "+longitudeValue.text+"°";
                pageOpen("NavigationRoute");
            }
        }
        StdButton {
            source:StyleSheet.back[StyleSheet.SOURCE]; x:StyleSheet.back[StyleSheet.X]; y:StyleSheet.back[StyleSheet.Y]; width:StyleSheet.back[StyleSheet.WIDTH]; height:StyleSheet.back[StyleSheet.HEIGHT];textColor:StyleSheet.backText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.backText[StyleSheet.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); explode:false; next:latitudeValue; prev:ok;
            onClicked:{
                Genivi.data['lat']='';
                Genivi.data['lon']='';
                pageOpen("NavigationSearch");
            }
        }
    }
}
