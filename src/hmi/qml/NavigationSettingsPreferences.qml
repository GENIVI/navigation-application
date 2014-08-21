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
    text: Genivi.gettext("NavigationSettingsPreferences")
    headlineFg: "grey"
    headlineBg: "blue"
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


    function array_contains(array, preferenceSource, preferenceMode)
	{
        var i;
		for (i = 0 ; i < array.length; i+=2) {
            if (array[i] == "structure") {
                var structure=array[i+1];
                if (structure[0] == "uint16" && structure[2] == "uint16") {
                    if (structure[1] == preferenceSource && structure[3] == preferenceMode)
                        return true;
                }
                else {
                    console.log("Unexpected result from GetSupportedRoutePreferences");
                    return false;
                }
            } else { return false; }
		}
		return false;
	}

    function update_preference(idyes, idno, supported, active, preferenceSource,preferenceMode)
	{
        if (array_contains(supported, preferenceSource, preferenceMode)) {
            if (array_contains(active, preferenceSource, preferenceMode)) {
				idyes.disabled=false;
				idno.disabled=true;
			} else {
				idyes.disabled=true;
				idno.disabled=false;
			}
		} else {
			idyes.disabled=true;
			idno.disabled=true;
		}
	}

	function update()
    { //only roadPreferenceList is managed
        var supported=Genivi.routing_message_get(dbusIf,"GetSupportedRoutePreferences",[]);
        var active=Genivi.routing_message_get(dbusIf,"GetRoutePreferences",["string",""]);
        if (supported[0] != 'array') {
			console.log("Unexpected result from GetSupportedRoutePreferences");
            Genivi.dump("",supported);
			return;
		}
        if (active[0] != 'array' || active[2] != 'array') {
			console.log("Unexpected result from GetRoutePreferences");
            Genivi.dump("",active);
			return;
		}
        // only three couples managed
        update_preference(ferries_yes,ferries_no,supported[1],active[1],Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_FERRY);
        update_preference(toll_roads_yes,toll_roads_no,supported[1],active[1],Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_TOLL_ROADS);
        update_preference(motorways_yes,motorways_no,supported[1],active[1],Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS);
	}

    function remove(preferenceSource,preferenceMode)
	{
        var active=Genivi.routing_message_get(dbusIf,"GetRoutePreferences",["string",""]); //preferences applied to all countries
        if (active[0] != 'array' || active[2] != 'array') {
			console.log("Unexpected result from GetRoutePreferences");
            Genivi.dump("",active);
			return;
		}

        var i,para=[],pref=[];
        para = para.concat("string","","array");

        for (i = 0 ; i < active[1].length; i+=2) {
            if (active[1][i] != 'structure') {
                console.log("Unexpected result from GetRoutePreferences");
                Genivi.dump("",active);
                return;
            }
            if (active[1][i+1][1] != preferenceSource || active[1][i+1][3] != preferenceMode) {
                pref = pref.concat(["structure"],[active[1][i+1]]);
            }
		}
        para = para.concat([pref],"array",[active[3]]);
        Genivi.routing_message(dbusIf,"SetRoutePreferences",para);
		update();
	}

    function add(preferenceSource,preferenceMode)
	{
        var active=Genivi.routing_message_get(dbusIf,"GetRoutePreferences",["string",""]);
        if (active[0] != 'array' || active[2] != 'array') {
			console.log("Unexpected result from GetRoutePreferences");
            Genivi.dump("",active);
			return;
		}

        var preferences = [["uint16", preferenceSource,"uint16", preferenceMode]];
        active[1] = active[1].concat("structure",preferences);

        var para = [];
        para = para.concat("string","",active);
        Genivi.routing_message(dbusIf,"SetRoutePreferences",para);
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
            id:ferries_yes; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_FERRY)}}
        StdButton { source:StyleSheet.avoid_ferries[Constants.SOURCE]; x:StyleSheet.avoid_ferries[Constants.X]; y:StyleSheet.avoid_ferries[Constants.Y]; width:StyleSheet.avoid_ferries[Constants.WIDTH]; height:StyleSheet.avoid_ferries[Constants.HEIGHT];
            id:ferries_no; next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_FERRY)}}

		Text {
            x:StyleSheet.tollRoadsText[Constants.X]; y:StyleSheet.tollRoadsText[Constants.Y]; width:StyleSheet.tollRoadsText[Constants.WIDTH]; height:StyleSheet.tollRoadsText[Constants.HEIGHT];color:StyleSheet.tollRoadsText[Constants.TEXTCOLOR];styleColor:StyleSheet.tollRoadsText[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.tollRoadsText[Constants.PIXELSIZE];
            id: tollRoadsText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("TollRoads")
        }
        StdButton { source:StyleSheet.allow_tollRoads[Constants.SOURCE]; x:StyleSheet.allow_tollRoads[Constants.X]; y:StyleSheet.allow_tollRoads[Constants.Y]; width:StyleSheet.allow_tollRoads[Constants.WIDTH]; height:StyleSheet.allow_tollRoads[Constants.HEIGHT];
            id:toll_roads_yes; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_TOLL_ROADS)}}
        StdButton { source:StyleSheet.avoid_tollRoads[Constants.SOURCE]; x:StyleSheet.avoid_tollRoads[Constants.X]; y:StyleSheet.avoid_tollRoads[Constants.Y]; width:StyleSheet.avoid_tollRoads[Constants.WIDTH]; height:StyleSheet.avoid_tollRoads[Constants.HEIGHT];
            id:toll_roads_no;  next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_TOLL_ROADS)}}

		Text {
            x:StyleSheet.motorWaysText[Constants.X]; y:StyleSheet.motorWaysText[Constants.Y]; width:StyleSheet.motorWaysText[Constants.WIDTH]; height:StyleSheet.motorWaysText[Constants.HEIGHT];color:StyleSheet.motorWaysText[Constants.TEXTCOLOR];styleColor:StyleSheet.motorWaysText[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.motorWaysText[Constants.PIXELSIZE];
            id:motorWaysText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("MotorWays")
        }
        StdButton { source:StyleSheet.allow_motorways[Constants.SOURCE]; x:StyleSheet.allow_motorways[Constants.X]; y:StyleSheet.allow_motorways[Constants.Y]; width:StyleSheet.allow_motorways[Constants.WIDTH]; height:StyleSheet.allow_motorways[Constants.HEIGHT];
            id:motorways_yes; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}
        StdButton { source:StyleSheet.avoid_motorways[Constants.SOURCE]; x:StyleSheet.avoid_motorways[Constants.X]; y:StyleSheet.avoid_motorways[Constants.Y]; width:StyleSheet.avoid_motorways[Constants.WIDTH]; height:StyleSheet.avoid_motorways[Constants.HEIGHT];
            id:motorways_no;  next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}

        StdButton { source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); disabled:false; next:back; prev:back; page:"NavigationSettings"}

	}

    Component.onCompleted: {
        var res=Genivi.routing_message(dbusIf,"GetCostModel",[]);
        var costmodel=0;
        if (res[0] == "uint16") {
            costmodel=res[1];
        } else {
            console.log("Unexpected result from GetCostModel");
            Genivi.dump("",res);
        }
        var res=Genivi.routing_message(dbusIf,"GetSupportedCostModels",[]);
        if (res[0] != "array") {
            console.log("Unexpected result from GetSupportedCostModel");
            Genivi.dump("",res);
        }
        for (var i = 0 ; i < res[1].length ; i+=2) {
            var button=Qt.createQmlObject('import QtQuick 2.1 ; import "Core"; StdButton { }',content,'dynamic');
            button.source="Core/images/cost-model.png";
            button.x=100;
            button.y=96+i*50;
            button.width=180;
            button.height=60;
            button.textColor="black";
            button.pixelSize=34;
            button.userdata=res[1][i+1];
            button.text=Genivi.CostModels[button.userdata];
            button.disabled=button.userdata == costmodel;
            button.clicked.connect(
                function(what) {
                    Genivi.routing_message(dbusIf,"SetCostModel",["uint16",what.userdata]);
                    pageOpen("NavigationSettingsPreferences");
                }
            );
        }

        update();
    }
}
