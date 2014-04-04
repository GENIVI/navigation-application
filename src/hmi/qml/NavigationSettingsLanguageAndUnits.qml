/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationSettingsLanguageAndUnits.qml
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
    text: Genivi.gettext("NavigationSettingsLanguageAndUnits")

	DBusIf {
		id: dbusIf 
	}

	function update()
	{
		var available_nav=Genivi.nav_message(dbusIf,"Configuration","GetSupportedLocales",[]);
		var available_map=Genivi.nav_message(dbusIf,"Configuration","GetSupportedLocales",[]);
		var current_nav=Genivi.nav_message(dbusIf,"Configuration","GetLocale",[]);
		var current_map=Genivi.map_message(dbusIf,"Configuration","GetLocale",[]);
		var current_lang_nav;
		var current_lang_map;
		var lang_nav=[];
		var lang_map=[];
		if (current_nav[0] == "string" && current_nav[2] == "string") {
			current_lang_nav=current_nav[1] + "_" + current_nav[3];
		} else {
			console.log("Unexpected result from GetLocale:");
			Genivi.dump("",current_nav);
		}
		if (current_map[0] == "string" && current_map[2] == "string") {
			current_lang_map=current_map[1] + "_" + current_map[3];
		} else {
			console.log("Unexpected result from GetLocale:");
			Genivi.dump("",current_map);
		}
		if (available_nav[0] == "array") {
			for (var i = 0 ; i < available_nav[1].length ; i+=2) {
				lang_nav[available_nav[1][i+1][1]+"_"+available_nav[1][i+1][3]]=true;
			}
		} else {
			console.log("Unexpected result from GetSupportedLocales:");
			Genivi.dump("",available_nav);
		}
		if (available_map[0] == "array") {
			for (var i = 0 ; i < available_map[1].length ; i+=2) {
				lang_map[available_map[1][i+1][1]+"_"+available_map[1][i+1][3]]=true;
			}
		} else {
			console.log("Unexpected result from GetSupportedLocales:");
			Genivi.dump("",available_map);
		}
		for (var i = 0 ; i < content.children.length ; i++) {
			var name=content.children[i].objectName;
			if (name) {
				if (lang_nav[name] && lang_map[name]) {
					content.children[i].visible=true;
					if (name == current_lang_nav && name == current_lang_map) {
						content.children[i].disabled=true;
					} else {
						content.children[i].disabled=false;
					}
				} else {
					content.children[i].visible=false;
				}
			}
		}
		var units1,units2;
		var res=Genivi.nav_message(dbusIf,"Configuration","GetUnitsOfMeasurement",[]);
		if (res[0] == "map" && res[1][0] == "uint16" && res[1][1] == Genivi.MAPVIEWER_LENGTH && res[1][2] == "variant" && res[1][3][0] == "uint16") {
			units1=res[1][3][1];
		} else {
			console.log("Unexpected result from GetUnitsOfMeasurement:");
			Genivi.dump("",res);
			units1=0;
		}
		var res=Genivi.map_message(dbusIf,"Configuration","GetUnitsOfMeasurement",[]);
		if (res[0] == "map" && res[1][0] == "uint16" && res[1][1] == Genivi.MAPVIEWER_LENGTH && res[1][2] == "variant" && res[1][3][0] == "uint16") {
			units2=res[1][3][1];
		} else {
			console.log("Unexpected result from GetUnitsOfMeasurement:");
			Genivi.dump("",res);
			units2=0;
		}
		unit_km.disabled=false;
		unit_mile.disabled=false;
		if (units1==Genivi.NAVIGATIONCORE_KM && units2==Genivi.MAPVIEWER_KM) unit_km.disabled=true;
		if (units1==Genivi.NAVIGATIONCORE_MILE && units2==Genivi.MAPVIEWER_MILE) unit_mile.disabled=true;
	}
	function setLocale(language, country)
	{
		Genivi.nav_message(dbusIf,"Configuration","SetLocale",["string",language,"string",country]);
		Genivi.map_message(dbusIf,"Configuration","SetLocale",["string",language,"string",country]);
		Genivi.setlang(language + "_" + country);
		pageOpen("NavigationSettingsLanguageAndUnits"); //reload page because of texts...
	}
	function setUnits(units1,units2)
	{
		Genivi.nav_message(dbusIf,"Configuration","SetUnitsOfMeasurement",["map",["uint16",Genivi.NAVIGATIONCORE_LENGTH,"variant",["uint16",units1]]]);
		Genivi.map_message(dbusIf,"Configuration","SetUnitsOfMeasurement",["map",["uint16",Genivi.MAPVIEWER_LENGTH,"variant",["uint16",units2]]]);
		update();
	}

	HMIBgImage {
		id: content
		image:"navigation-settings-language-and-units-menu-background";
//Important notice: x,y coordinates from the left/top origin, so take in account the header of 26 pixels high
		anchors { fill: parent; topMargin: parent.headlineHeight}

		Text {
                height:menu.hspc
				x:100; y:26;
                font.pixelSize: 25;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: Genivi.gettext("Language")
             }
		StdButton { objectName:"fra_FRA"; source:"Core/images/french.png"; x:100; y:66; width:100; height:60; id:fr_FR; disabled:false; next:back; prev:back; explode:false; onClicked: {setLocale("fra","FRA");}}
		StdButton { objectName:"deu_DEU"; source:"Core/images/german.png"; x:100; y:140; width:100; height:60; id:de_DE; disabled:false; next:back; prev:back; explode:false; onClicked: {setLocale("deu","DEU");}}
		StdButton { objectName:"eng_USA"; source:"Core/images/us-english.png"; x:100; y:214; width:100; height:60; id:en_US; disabled:false; next:back; prev:back; explode:false; onClicked: {setLocale("eng","USA");}}
		StdButton { objectName:"jpn_JPN"; source:"Core/images/japanese.png"; x:100; y:288; width:100; height:60; id:jp_JP; disabled:false; next:back; prev:back; explode:false; onClicked: {setLocale("jpn","JPN");}}
		StdButton { textColor:"black"; pixelSize:38 ; source:"Core/images/back.png"; x:600; y:374; width:180; height:60; id:back; text: Genivi.gettext("Back"); disabled:false; next:back; prev:back; page:"NavigationSettings"}

		Text {
                height:menu.hspc
				x:330; y:26;
                font.pixelSize: 25;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: Genivi.gettext("Units")
             }
		StdButton { source:"Core/images/unit-km.png"; x:330; y:66; width:100; height:60; id:unit_km; explode:false; disabled:false; next:back; prev:back;
			onClicked: {
				setUnits(Genivi.NAVIGATIONCORE_KM,Genivi.MAPVIEWER_KM);}
		}
		StdButton { source:"Core/images/unit-mile.png"; x:330; y:140; width:100; height:60; id:unit_mile; explode:false; disabled:false; next:back; prev:back;
			onClicked: {
				setUnits(Genivi.NAVIGATIONCORE_MILE,Genivi.MAPVIEWER_MILE);}
		}

		
		Component.onCompleted: {
			update();
		}
	}
}
