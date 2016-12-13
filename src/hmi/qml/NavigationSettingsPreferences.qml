/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationSettingsPreferences.qml
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
import "Core/style-sheets/navigation-settings-preference-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0
import lbs.plugin.preference 1.0

HMIMenu {
	id: menu
    property string pagefile:"NavigationSettingsPreferences"

    DBusIf {
        id: dbusIf
    }

// please note that the preferences are hard coded, limited to three couples:
//    (NAVIGATIONCORE_AVOID,NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)
//    (NAVIGATIONCORE_AVOID,NAVIGATIONCORE_TOLL_ROADS)
//    (NAVIGATIONCORE_AVOID,NAVIGATIONCORE_FERRY)

    Preference {
        source: 0
        mode: 0
    }

	function update()
    {
        Genivi.routing_SetRoutePreferences(dbusIf,""); //preferences applied to all countries
        var active=Genivi.routing_GetRoutePreferences(dbusIf,"");

        var roadPreferenceList;
        var conditionPreferenceList;
        roadPreferenceList=active[1];
        conditionPreferenceList=active[3];
        var roadPreferenceMode,roadPreferenceSource;
        var conditionPreferenceMode,conditionPreferenceSource;

        for(var i=0; i<roadPreferenceList.length; i+=2)
        {
            roadPreferenceMode=roadPreferenceList[i+1][1];
            roadPreferenceSource=roadPreferenceList[i+1][3];
            Genivi.roadPreferenceList[roadPreferenceSource]=roadPreferenceMode;

            if(roadPreferenceSource == Genivi.NAVIGATIONCORE_FERRY)
            {
                if(roadPreferenceMode == Genivi.NAVIGATIONCORE_AVOID)
                {
                    ferries_yes.disabled=false;
                    ferries_no.disabled=true;
                }
                else
                {
                    ferries_yes.disabled=true;
                    ferries_no.disabled=false;
                }
            }
            else
            {
                if(roadPreferenceSource == Genivi.NAVIGATIONCORE_TOLL_ROADS)
                {
                    if(roadPreferenceMode == Genivi.NAVIGATIONCORE_AVOID)
                    {
                        toll_roads_yes.disabled=false;
                        toll_roads_no.disabled=true;
                    }
                    else
                    {
                        toll_roads_yes.disabled=true;
                        toll_roads_no.disabled=false;
                    }
                }
                else
                {
                    if(roadPreferenceSource == Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)
                    {
                        if(roadPreferenceMode == Genivi.NAVIGATIONCORE_AVOID)
                        {
                            motorways_yes.disabled=false;
                            motorways_no.disabled=true;
                        }
                        else
                        {
                            motorways_yes.disabled=true;
                            motorways_no.disabled=false;
                        }
                    }
                }
            }
        }
	}

    function use(preferenceSource)
	{
        Genivi.roadPreferenceList[preferenceSource]=Genivi.NAVIGATIONCORE_USE;
		update();
	}

    function avoid(preferenceSource)
	{
        Genivi.roadPreferenceList[preferenceSource]=Genivi.NAVIGATIONCORE_AVOID;
		update();
	}

	HMIBgImage {
		id: content
        image:StyleSheet.navigation_settings_preference_menu_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}
		Text {
            x:StyleSheet.costModelTitle[Constants.X]; y:StyleSheet.costModelTitle[Constants.Y]; width:StyleSheet.costModelTitle[Constants.WIDTH]; height:StyleSheet.costModelTitle[Constants.HEIGHT];color:StyleSheet.costModelTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.costModelTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.costModelTitle[Constants.PIXELSIZE];
            id:costModelTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("CostModel")
        }

		Text {
            x:StyleSheet.routingPreferencesTitle[Constants.X]; y:StyleSheet.routingPreferencesTitle[Constants.Y]; width:StyleSheet.routingPreferencesTitle[Constants.WIDTH]; height:StyleSheet.routingPreferencesTitle[Constants.HEIGHT];color:StyleSheet.routingPreferencesTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.routingPreferencesTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.routingPreferencesTitle[Constants.PIXELSIZE];
            id:routingPreferencesTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("RoutingPreferences")
        }

		Text {
            x:StyleSheet.ferriesText[Constants.X]; y:StyleSheet.ferriesText[Constants.Y]; width:StyleSheet.ferriesText[Constants.WIDTH]; height:StyleSheet.ferriesText[Constants.HEIGHT];color:StyleSheet.ferriesText[Constants.TEXTCOLOR];styleColor:StyleSheet.ferriesText[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.ferriesText[Constants.PIXELSIZE];
            id: ferriesText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Ferries")
        }
        StdButton { source:StyleSheet.allow_ferries[Constants.SOURCE]; x:StyleSheet.allow_ferries[Constants.X]; y:StyleSheet.allow_ferries[Constants.Y]; width:StyleSheet.allow_ferries[Constants.WIDTH]; height:StyleSheet.allow_ferries[Constants.HEIGHT];
            id:ferries_yes; next:back; prev:back;  onClicked:{use(Genivi.NAVIGATIONCORE_FERRY)}}
        StdButton { source:StyleSheet.avoid_ferries[Constants.SOURCE]; x:StyleSheet.avoid_ferries[Constants.X]; y:StyleSheet.avoid_ferries[Constants.Y]; width:StyleSheet.avoid_ferries[Constants.WIDTH]; height:StyleSheet.avoid_ferries[Constants.HEIGHT];
            id:ferries_no; next:back; prev:back;  onClicked:{avoid(Genivi.NAVIGATIONCORE_FERRY)}}

		Text {
            x:StyleSheet.tollRoadsText[Constants.X]; y:StyleSheet.tollRoadsText[Constants.Y]; width:StyleSheet.tollRoadsText[Constants.WIDTH]; height:StyleSheet.tollRoadsText[Constants.HEIGHT];color:StyleSheet.tollRoadsText[Constants.TEXTCOLOR];styleColor:StyleSheet.tollRoadsText[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.tollRoadsText[Constants.PIXELSIZE];
            id: tollRoadsText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("TollRoads")
        }
        StdButton { source:StyleSheet.allow_tollRoads[Constants.SOURCE]; x:StyleSheet.allow_tollRoads[Constants.X]; y:StyleSheet.allow_tollRoads[Constants.Y]; width:StyleSheet.allow_tollRoads[Constants.WIDTH]; height:StyleSheet.allow_tollRoads[Constants.HEIGHT];
            id:toll_roads_yes; next:back; prev:back;  onClicked:{use(Genivi.NAVIGATIONCORE_TOLL_ROADS)}}
        StdButton { source:StyleSheet.avoid_tollRoads[Constants.SOURCE]; x:StyleSheet.avoid_tollRoads[Constants.X]; y:StyleSheet.avoid_tollRoads[Constants.Y]; width:StyleSheet.avoid_tollRoads[Constants.WIDTH]; height:StyleSheet.avoid_tollRoads[Constants.HEIGHT];
            id:toll_roads_no;  next:back; prev:back;  onClicked:{avoid(Genivi.NAVIGATIONCORE_TOLL_ROADS)}}

		Text {
            x:StyleSheet.motorWaysText[Constants.X]; y:StyleSheet.motorWaysText[Constants.Y]; width:StyleSheet.motorWaysText[Constants.WIDTH]; height:StyleSheet.motorWaysText[Constants.HEIGHT];color:StyleSheet.motorWaysText[Constants.TEXTCOLOR];styleColor:StyleSheet.motorWaysText[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.motorWaysText[Constants.PIXELSIZE];
            id:motorWaysText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("MotorWays")
        }
        StdButton { source:StyleSheet.allow_motorways[Constants.SOURCE]; x:StyleSheet.allow_motorways[Constants.X]; y:StyleSheet.allow_motorways[Constants.Y]; width:StyleSheet.allow_motorways[Constants.WIDTH]; height:StyleSheet.allow_motorways[Constants.HEIGHT];
            id:motorways_yes; next:back; prev:back;  onClicked:{use(Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}
        StdButton { source:StyleSheet.avoid_motorways[Constants.SOURCE]; x:StyleSheet.avoid_motorways[Constants.X]; y:StyleSheet.avoid_motorways[Constants.Y]; width:StyleSheet.avoid_motorways[Constants.WIDTH]; height:StyleSheet.avoid_motorways[Constants.HEIGHT];
            id:motorways_no;  next:back; prev:back;  onClicked:{avoid(Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}

        StdButton { source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); disabled:false; next:back; prev:back; onClicked:{leaveMenu();}}

	}

    Component.onCompleted: {
        var res=Genivi.routing_GetCostModel(dbusIf);
        var costmodel=res[1];
        var costModelsList=Genivi.routing_GetSupportedCostModels(dbusIf);
        for (var i = 0 ; i < costModelsList[1].length ; i+=2) {
            var button=Qt.createQmlObject('import QtQuick 2.1 ; import "Core"; StdButton { }',content,'dynamic');
            button.source=StyleSheet.cost_model[Constants.SOURCE];
            button.x=StyleSheet.cost_model[Constants.X];
            button.y=StyleSheet.cost_model[Constants.Y] + i*50; //to be improved
            button.width=StyleSheet.cost_model[Constants.WIDTH];
            button.height=StyleSheet.cost_model[Constants.HEIGHT];
            button.textColor=StyleSheet.costModelValue[Constants.TEXTCOLOR];
            button.pixelSize=StyleSheet.costModelValue[Constants.PIXELSIZE];
            button.userdata=costModelsList[1][i+1];
            button.text=Genivi.CostModels[button.userdata];
            button.disabled=button.userdata == costmodel;
            button.clicked.connect(
                function(what) {
                    Genivi.routing_SetCostModel(dbusIf,what.userdata);
                    pageOpen(menu.pagefile); //reload the page
                }
            );
        }

        update();
    }
}
