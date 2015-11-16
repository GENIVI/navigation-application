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
import QtQuick 2.1 
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/navigation-search-coordinates-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
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
        image:StyleSheet.navigation_search_by_coordinates_menu_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

        Text {
            x:StyleSheet.latitudeTitle[Constants.X]; y:StyleSheet.latitudeTitle[Constants.Y]; width:StyleSheet.latitudeTitle[Constants.WIDTH]; height:StyleSheet.latitudeTitle[Constants.HEIGHT];color:StyleSheet.latitudeTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.latitudeTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.latitudeTitle[Constants.PIXELSIZE];
            id:latitudeTitle;
            style: Text.Sunken;
            smooth: true;
            text: Genivi.gettext("Latitude");
        }
        EntryField {
            x:StyleSheet.latitudeValue[Constants.X]; y:StyleSheet.latitudeValue[Constants.Y]; width: StyleSheet.latitudeValue[Constants.WIDTH]; height: StyleSheet.latitudeValue[Constants.HEIGHT];
            id: latitudeValue
			globaldata: 'lat'
			textfocus: true
            next: longitudeValue
			prev: back
			onLeave:{menu.leave(0)}
		}
        Text {
            x:StyleSheet.longitudeTitle[Constants.X]; y:StyleSheet.longitudeTitle[Constants.Y]; width:StyleSheet.longitudeTitle[Constants.WIDTH]; height:StyleSheet.longitudeTitle[Constants.HEIGHT];color:StyleSheet.longitudeTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.longitudeTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.longitudeTitle[Constants.PIXELSIZE];
            id:longitudeTitle;
            style: Text.Sunken;
            smooth: true;
            text: Genivi.gettext("Longitude");
        }
		EntryField {
            x:StyleSheet.longitudeValue[Constants.X]; y:StyleSheet.longitudeValue[Constants.Y]; width: StyleSheet.longitudeValue[Constants.WIDTH]; height: StyleSheet.longitudeValue[Constants.HEIGHT];
            id: longitudeValue
			globaldata: 'lon'
			next: ok
            prev: latitudeValue
			onLeave:{menu.leave(0)}
		}
        StdButton {
            source:StyleSheet.ok[Constants.SOURCE]; x:StyleSheet.ok[Constants.X]; y:StyleSheet.ok[Constants.Y]; width:StyleSheet.ok[Constants.WIDTH]; height:StyleSheet.ok[Constants.HEIGHT];textColor:StyleSheet.okText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.okText[Constants.PIXELSIZE];
            id:ok
            next:back
            prev:longitudeValue
            text:Genivi.gettext("Ok")
            disabled: true
            onClicked:{
                Genivi.data['lat']=latitudeValue.text;
                Genivi.data['lon']=longitudeValue.text;
                Genivi.data['description']="Latitude "+latitudeValue.text+"° Longitude "+longitudeValue.text+"°";
                routeMenu();
            }
        }
        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); explode:false; next:latitudeValue; prev:ok;
            onClicked:{
                Genivi.data['lat']='';
                Genivi.data['lon']='';
                leaveMenu();
            }
        }
    }
}
