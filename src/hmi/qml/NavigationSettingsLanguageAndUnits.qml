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
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/navigation-settings-language-and-units-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    property string pagefile:"NavigationSettingsLanguageAndUnits"
    property Item configurationChangedSignal;

	DBusIf {
		id: dbusIf 
	}

    function configurationChanged(args)
    { //to be improved !
        Genivi.hookSignal("configurationChanged");
        for (var i=0; i < args[1].length;i+=2) {
            switch (args[1][i+1]) {
            case Genivi.NAVIGATIONCORE_LOCALE:
                update();
                break;
            case Genivi.NAVIGATIONCORE_UNITS_OF_MEASUREMENT:
                update();
                break;
            }
        }
    }

    function connectSignals()
    {
        configurationChangedSignal=Genivi.connect_configurationChangedSignal(dbusIf,menu);
    }

    function disconnectSignals()
    {
        configurationChangedSignal.destroy();
    }

	function update()
	{
        var available_nav=Genivi.navigationcore_configuration_GetSupportedLocales(dbusIf);
        var available_map=Genivi.mapviewer_configuration_GetSupportedLocales(dbusIf);
        var current_nav=Genivi.navigationcore_configuration_GetLocale(dbusIf);
        var current_map=Genivi.mapviewer_configuration_GetLocale(dbusIf);
		var current_lang_nav;
		var current_lang_map;
		var lang_nav=[];
		var lang_map=[];

        current_lang_nav=current_nav[1] + "_" + current_nav[3];
        current_lang_map=current_map[1] + "_" + current_map[3];

        for (var i = 0 ; i < available_nav[1].length ; i+=2) {
            lang_nav[available_nav[1][i+1][1]+"_"+available_nav[1][i+1][3]]=true;
        }

        for (var i = 0 ; i < available_map[1].length ; i+=2) {
            lang_map[available_map[1][i+1][1]+"_"+available_map[1][i+1][3]]=true;
        }

        // only the locales for nav are used
        for (var i = 0 ; i < content.children.length ; i++) {
			var name=content.children[i].objectName;
			if (name) {
                content.children[i].visible=true;
                if (name == current_lang_nav) {
                    content.children[i].disabled=true;
                }
                else {
                    content.children[i].disabled=false;
                }
            }
		}

        Genivi.setlang(current_lang_nav);

		var units1,units2;
        var res=Genivi.navigationcore_configuration_GetUnitsOfMeasurement(dbusIf);

        if (res[1][1] == Genivi.NAVIGATIONCORE_LENGTH) {
            units1=res[1][3];
        }
        var res1=Genivi.mapviewer_configuration_GetUnitsOfMeasurement(dbusIf);
        if (res1[1][1] == Genivi.MAPVIEWER_LENGTH) {
            units2=res1[1][3];
        }
		unit_km.disabled=false;
		unit_mile.disabled=false;
        if (units1==Genivi.NAVIGATIONCORE_KM) unit_km.disabled=true;
        if (units1==Genivi.NAVIGATIONCORE_MILE) unit_mile.disabled=true;
	}

    function setLocale(language, country, script)
	{
        Genivi.navigationcore_configuration_SetLocale(dbusIf,language,country,script);
        Genivi.mapviewer_configuration_SetLocale(dbusIf,language,country,script);
        Genivi.setlang(language + "_" + country);
        pageOpen(menu.pagefile); //reload page because of texts...
    }
    function setUnitsLength(units1,units2)
	{
        Genivi.navigationcore_configuration_SetUnitsOfMeasurementLength(dbusIf,units1);
        Genivi.mapviewer_configuration_SetUnitsOfMeasurementLength(dbusIf,units2);
		update();
	}

	HMIBgImage {
		id: content
        image:StyleSheet.navigation_settings_language_and_units_menu_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

		Text {
            x:StyleSheet.languagesTitle[Constants.X]; y:StyleSheet.languagesTitle[Constants.Y]; width:StyleSheet.languagesTitle[Constants.WIDTH]; height:StyleSheet.languagesTitle[Constants.HEIGHT];color:StyleSheet.languagesTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.languagesTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.languagesTitle[Constants.PIXELSIZE];
            id:languagesTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Language")
             }
        StdButton { objectName:"fra_FRA";
            source:StyleSheet.french_flag[Constants.SOURCE]; x:StyleSheet.french_flag[Constants.X]; y:StyleSheet.french_flag[Constants.Y]; width:StyleSheet.french_flag[Constants.WIDTH]; height:StyleSheet.french_flag[Constants.HEIGHT];
            id:fra_FRA; disabled:false; next:deu_DEU; prev:back; explode:false; onClicked: {setLocale("fra","FRA","Latn");}}
        StdButton { objectName:"deu_DEU";
            source:StyleSheet.german_flag[Constants.SOURCE]; x:StyleSheet.german_flag[Constants.X]; y:StyleSheet.german_flag[Constants.Y]; width:StyleSheet.german_flag[Constants.WIDTH]; height:StyleSheet.german_flag[Constants.HEIGHT];
             id:deu_DEU; disabled:false; next:eng_USA; prev:fra_FRA; explode:false; onClicked: {setLocale("deu","DEU","Latn");}}
        StdButton { objectName:"eng_USA";
            source:StyleSheet.usa_flag[Constants.SOURCE]; x:StyleSheet.usa_flag[Constants.X]; y:StyleSheet.usa_flag[Constants.Y]; width:StyleSheet.usa_flag[Constants.WIDTH]; height:StyleSheet.usa_flag[Constants.HEIGHT];
            id:eng_USA; disabled:false; next:jpn_JPN; prev:deu_DEU; explode:false; onClicked: {setLocale("eng","USA","Latn");}}
        StdButton { objectName:"jpn_JPN";
            source:StyleSheet.japanese_flag[Constants.SOURCE]; x:StyleSheet.japanese_flag[Constants.X]; y:StyleSheet.japanese_flag[Constants.Y]; width:StyleSheet.japanese_flag[Constants.WIDTH]; height:StyleSheet.japanese_flag[Constants.HEIGHT];
            id:jpn_JPN; disabled:false; next:back; prev:eng_USA; explode:false; onClicked: {setLocale("jpn","JPN","Hrkt");}}

		Text {
            x:StyleSheet.unitsTitle[Constants.X]; y:StyleSheet.unitsTitle[Constants.Y]; width:StyleSheet.unitsTitle[Constants.WIDTH]; height:StyleSheet.unitsTitle[Constants.HEIGHT];color:StyleSheet.unitsTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.unitsTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.unitsTitle[Constants.PIXELSIZE];
            id:unitsTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Units")
             }
        StdButton { source:StyleSheet.unit_km[Constants.SOURCE]; x:StyleSheet.unit_km[Constants.X]; y:StyleSheet.unit_km[Constants.Y]; width:StyleSheet.unit_km[Constants.WIDTH]; height:StyleSheet.unit_km[Constants.HEIGHT];
            id:unit_km; explode:false; disabled:false; next:back; prev:back;
			onClicked: {
                setUnitsLength(Genivi.NAVIGATIONCORE_KM,Genivi.MAPVIEWER_KM);}
		}
        StdButton { source:StyleSheet.unit_mile[Constants.SOURCE]; x:StyleSheet.unit_mile[Constants.X]; y:StyleSheet.unit_mile[Constants.Y]; width:StyleSheet.unit_mile[Constants.WIDTH]; height:StyleSheet.unit_mile[Constants.HEIGHT];
            id:unit_mile; explode:false; disabled:false; next:back; prev:back;
			onClicked: {
                setUnitsLength(Genivi.NAVIGATIONCORE_MILE,Genivi.MAPVIEWER_MILE);}
		}
        StdButton { source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); disabled:false; next:back; prev:back;
            onClicked:{
                disconnectSignals();
                leaveMenu();
            }
        }

	}

    Component.onCompleted: {
        connectSignals();
        update();
    }
}
