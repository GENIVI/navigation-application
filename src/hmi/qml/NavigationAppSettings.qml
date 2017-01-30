/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationSettings.qml
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
import "Core/style-sheets/NavigationAppSettings-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

NavigationAppHMIMenu {
	id: menu
    property string pagefile:"NavigationAppSettings"
    next: back
        prev: back

    DBusIf {
		id:dbusIf;
	}

    NavigationAppHMIBgImage {
		id: content
        image:StyleSheet.navigation_app_settings_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

		Text {
            x:StyleSheet.simulationTitle[Constants.X]; y:StyleSheet.simulationTitle[Constants.Y]; width:StyleSheet.simulationTitle[Constants.WIDTH]; height:StyleSheet.simulationTitle[Constants.HEIGHT];color:StyleSheet.simulationTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.simulationTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.simulationTitle[Constants.PIXELSIZE];
            id:simulationTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Simulation")
             }

        StdButton {
            x:StyleSheet.simu_mode_enable[Constants.X]; y:StyleSheet.simu_mode_enable[Constants.Y]; width:StyleSheet.simu_mode_enable[Constants.WIDTH]; height:StyleSheet.simu_mode_enable[Constants.HEIGHT];
            id:simu_mode; next:back; prev:preferences;  disabled:false;
            source:
            {
                if (Genivi.simulationMode==true)
                {
                    source=StyleSheet.simu_mode_enable[Constants.SOURCE];
                }
                else
                {
                    source=StyleSheet.simu_mode_disable[Constants.SOURCE];
                }
            }

            function setState(name)
            {
                if (name=="ENABLE")
                {
                    source=StyleSheet.simu_mode_enable[Constants.SOURCE];
                }
                else
                {
                    source=StyleSheet.simu_mode_disable[Constants.SOURCE];
                }
            }
            onClicked:
            {
                if (Genivi.simulationMode==true)
                { //hide the panel
                    Genivi.simulationMode=false;
                    simu_mode.setState("DISABLE");
                }
                else
                { //show the panel
                    Genivi.simulationMode=true;
                    simu_mode.setState("ENABLE");
                }
            }
        }

        StdButton {
            source:StyleSheet.preferences[Constants.SOURCE]; x:StyleSheet.preferences[Constants.X]; y:StyleSheet.preferences[Constants.Y]; width:StyleSheet.preferences[Constants.WIDTH]; height:StyleSheet.preferences[Constants.HEIGHT];textColor:StyleSheet.preferencesText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.preferencesText[Constants.PIXELSIZE];
            id:preferences; text: Genivi.gettext("Preference"); disabled:false; next:languageAndUnit; prev:back;
            onClicked: {
                entryMenu("NavigationAppSettingsPreferences",menu);
            }
        }

        StdButton {
            source:StyleSheet.languageAndUnit[Constants.SOURCE]; x:StyleSheet.languageAndUnit[Constants.X]; y:StyleSheet.languageAndUnit[Constants.Y]; width:StyleSheet.languageAndUnit[Constants.WIDTH]; height:StyleSheet.languageAndUnit[Constants.HEIGHT];textColor:StyleSheet.languageAndUnitText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.languageAndUnitText[Constants.PIXELSIZE];
            id:languageAndUnit; text: Genivi.gettext("LanguageAndUnits"); disabled:false; next:back; prev:preferences;
            onClicked: {
                entryMenu("NavigationAppSettingsLanguageAndUnits",menu);
            }
        }

        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); disabled:false; next:simu_mode; prev:languageAndUnit;
            onClicked:{leaveMenu();}
        }

	}

    Component.onCompleted: {
    }
}
