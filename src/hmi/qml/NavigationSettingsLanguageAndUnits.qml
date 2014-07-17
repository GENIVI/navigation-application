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
import QtQuick 2.1 
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/navigation-settings-language-and-units-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

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
        var res1=Genivi.map_message(dbusIf,"Configuration","GetUnitsOfMeasurement",[]);
        if (res1[0] == "map" && res1[1][0] == "uint16" && res1[1][1] == Genivi.MAPVIEWER_LENGTH && res1[1][2] == "variant" && res1[1][3][0] == "uint16") {
            units2=res1[1][3][1];
		} else {
			console.log("Unexpected result from GetUnitsOfMeasurement:");
            Genivi.dump("",res1);
			units2=0;
		}
		unit_km.disabled=false;
		unit_mile.disabled=false;
		if (units1==Genivi.NAVIGATIONCORE_KM && units2==Genivi.MAPVIEWER_KM) unit_km.disabled=true;
		if (units1==Genivi.NAVIGATIONCORE_MILE && units2==Genivi.MAPVIEWER_MILE) unit_mile.disabled=true;
        console.log("update done");
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
        image:StyleSheet.navigation_settings_language_and_units_menu_background[StyleSheet.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

		Text {
            x:StyleSheet.languagesTitle[StyleSheet.X]; y:StyleSheet.languagesTitle[StyleSheet.Y]; width:StyleSheet.languagesTitle[StyleSheet.WIDTH]; height:StyleSheet.languagesTitle[StyleSheet.HEIGHT];color:StyleSheet.languagesTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.languagesTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.languagesTitle[StyleSheet.PIXELSIZE];
            id:languagesTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Language")
             }
        StdButton { objectName:"fra_FRA";
            source:StyleSheet.french_flag[StyleSheet.SOURCE]; x:StyleSheet.french_flag[StyleSheet.X]; y:StyleSheet.french_flag[StyleSheet.Y]; width:StyleSheet.french_flag[StyleSheet.WIDTH]; height:StyleSheet.french_flag[StyleSheet.HEIGHT];
            id:fra_FRA; disabled:false; next:deu_DEU; prev:back; explode:false; onClicked: {setLocale("fra","FRA");}}
        StdButton { objectName:"deu_DEU";
            source:StyleSheet.german_flag[StyleSheet.SOURCE]; x:StyleSheet.german_flag[StyleSheet.X]; y:StyleSheet.german_flag[StyleSheet.Y]; width:StyleSheet.german_flag[StyleSheet.WIDTH]; height:StyleSheet.german_flag[StyleSheet.HEIGHT];
             id:deu_DEU; disabled:false; next:eng_USA; prev:fra_FRA; explode:false; onClicked: {setLocale("deu","DEU");}}
        StdButton { objectName:"eng_USA";
            source:StyleSheet.usa_flag[StyleSheet.SOURCE]; x:StyleSheet.usa_flag[StyleSheet.X]; y:StyleSheet.usa_flag[StyleSheet.Y]; width:StyleSheet.usa_flag[StyleSheet.WIDTH]; height:StyleSheet.usa_flag[StyleSheet.HEIGHT];
            id:eng_USA; disabled:false; next:jpn_JPN; prev:deu_DEU; explode:false; onClicked: {setLocale("eng","USA");}}
        StdButton { objectName:"jpn_JPN";
            source:StyleSheet.japanese_flag[StyleSheet.SOURCE]; x:StyleSheet.japanese_flag[StyleSheet.X]; y:StyleSheet.japanese_flag[StyleSheet.Y]; width:StyleSheet.japanese_flag[StyleSheet.WIDTH]; height:StyleSheet.japanese_flag[StyleSheet.HEIGHT];
            id:jpn_JPN; disabled:false; next:back; prev:eng_USA; explode:false; onClicked: {setLocale("jpn","JPN");}}

		Text {
            x:StyleSheet.unitsTitle[StyleSheet.X]; y:StyleSheet.unitsTitle[StyleSheet.Y]; width:StyleSheet.unitsTitle[StyleSheet.WIDTH]; height:StyleSheet.unitsTitle[StyleSheet.HEIGHT];color:StyleSheet.unitsTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.unitsTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.unitsTitle[StyleSheet.PIXELSIZE];
            id:unitsTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Units")
             }
        StdButton { source:StyleSheet.unit_km[StyleSheet.SOURCE]; x:StyleSheet.unit_km[StyleSheet.X]; y:StyleSheet.unit_km[StyleSheet.Y]; width:StyleSheet.unit_km[StyleSheet.WIDTH]; height:StyleSheet.unit_km[StyleSheet.HEIGHT];
            id:unit_km; explode:false; disabled:false; next:back; prev:back;
			onClicked: {
				setUnits(Genivi.NAVIGATIONCORE_KM,Genivi.MAPVIEWER_KM);}
		}
        StdButton { source:StyleSheet.unit_mile[StyleSheet.SOURCE]; x:StyleSheet.unit_mile[StyleSheet.X]; y:StyleSheet.unit_mile[StyleSheet.Y]; width:StyleSheet.unit_mile[StyleSheet.WIDTH]; height:StyleSheet.unit_mile[StyleSheet.HEIGHT];
            id:unit_mile; explode:false; disabled:false; next:back; prev:back;
			onClicked: {
				setUnits(Genivi.NAVIGATIONCORE_MILE,Genivi.MAPVIEWER_MILE);}
		}
        StdButton { source:StyleSheet.back[StyleSheet.SOURCE]; x:StyleSheet.back[StyleSheet.X]; y:StyleSheet.back[StyleSheet.Y]; width:StyleSheet.back[StyleSheet.WIDTH]; height:StyleSheet.back[StyleSheet.HEIGHT];textColor:StyleSheet.backText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.backText[StyleSheet.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); disabled:false; next:back; prev:back; page:"NavigationSettings"}

	}

    Component.onCompleted: {
        update();
    }
}
