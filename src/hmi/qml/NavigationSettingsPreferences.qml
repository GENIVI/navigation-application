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
        image:StyleSheet.navigation_settings_preference_menu_background[StyleSheet.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}
		Text {
            x:StyleSheet.costModelTitle[StyleSheet.X]; y:StyleSheet.costModelTitle[StyleSheet.Y]; width:StyleSheet.costModelTitle[StyleSheet.WIDTH]; height:StyleSheet.costModelTitle[StyleSheet.HEIGHT];color:StyleSheet.costModelTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.costModelTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.costModelTitle[StyleSheet.PIXELSIZE];
            id:costModelTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("CostModel")
        }

		Text {
            x:StyleSheet.routingPreferencesTitle[StyleSheet.X]; y:StyleSheet.routingPreferencesTitle[StyleSheet.Y]; width:StyleSheet.routingPreferencesTitle[StyleSheet.WIDTH]; height:StyleSheet.routingPreferencesTitle[StyleSheet.HEIGHT];color:StyleSheet.routingPreferencesTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.routingPreferencesTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.routingPreferencesTitle[StyleSheet.PIXELSIZE];
            id:routingPreferencesTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("RoutingPreferences")
        }

		Text {
            x:StyleSheet.ferriesText[StyleSheet.X]; y:StyleSheet.ferriesText[StyleSheet.Y]; width:StyleSheet.ferriesText[StyleSheet.WIDTH]; height:StyleSheet.ferriesText[StyleSheet.HEIGHT];color:StyleSheet.ferriesText[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.ferriesText[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.ferriesText[StyleSheet.PIXELSIZE];
            id: ferriesText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Ferries")
        }
        StdButton { source:StyleSheet.allow_ferries[StyleSheet.SOURCE]; x:StyleSheet.allow_ferries[StyleSheet.X]; y:StyleSheet.allow_ferries[StyleSheet.Y]; width:StyleSheet.allow_ferries[StyleSheet.WIDTH]; height:StyleSheet.allow_ferries[StyleSheet.HEIGHT];
            id:ferries_yes; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_FERRY)}}
        StdButton { source:StyleSheet.avoid_ferries[StyleSheet.SOURCE]; x:StyleSheet.avoid_ferries[StyleSheet.X]; y:StyleSheet.avoid_ferries[StyleSheet.Y]; width:StyleSheet.avoid_ferries[StyleSheet.WIDTH]; height:StyleSheet.avoid_ferries[StyleSheet.HEIGHT];
            id:ferries_no; next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_FERRY)}}

		Text {
            x:StyleSheet.tollRoadsText[StyleSheet.X]; y:StyleSheet.tollRoadsText[StyleSheet.Y]; width:StyleSheet.tollRoadsText[StyleSheet.WIDTH]; height:StyleSheet.tollRoadsText[StyleSheet.HEIGHT];color:StyleSheet.tollRoadsText[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.tollRoadsText[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.tollRoadsText[StyleSheet.PIXELSIZE];
            id: tollRoadsText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("TollRoads")
        }
        StdButton { source:StyleSheet.allow_tollRoads[StyleSheet.SOURCE]; x:StyleSheet.allow_tollRoads[StyleSheet.X]; y:StyleSheet.allow_tollRoads[StyleSheet.Y]; width:StyleSheet.allow_tollRoads[StyleSheet.WIDTH]; height:StyleSheet.allow_tollRoads[StyleSheet.HEIGHT];
            id:toll_roads_yes; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_TOLL_ROADS)}}
        StdButton { source:StyleSheet.avoid_tollRoads[StyleSheet.SOURCE]; x:StyleSheet.avoid_tollRoads[StyleSheet.X]; y:StyleSheet.avoid_tollRoads[StyleSheet.Y]; width:StyleSheet.avoid_tollRoads[StyleSheet.WIDTH]; height:StyleSheet.avoid_tollRoads[StyleSheet.HEIGHT];
            id:toll_roads_no;  next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_TOLL_ROADS)}}

		Text {
            x:StyleSheet.motorWaysText[StyleSheet.X]; y:StyleSheet.motorWaysText[StyleSheet.Y]; width:StyleSheet.motorWaysText[StyleSheet.WIDTH]; height:StyleSheet.motorWaysText[StyleSheet.HEIGHT];color:StyleSheet.motorWaysText[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.motorWaysText[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.motorWaysText[StyleSheet.PIXELSIZE];
            id:motorWaysText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("MotorWays")
        }
        StdButton { source:StyleSheet.allow_motorways[StyleSheet.SOURCE]; x:StyleSheet.allow_motorways[StyleSheet.X]; y:StyleSheet.allow_motorways[StyleSheet.Y]; width:StyleSheet.allow_motorways[StyleSheet.WIDTH]; height:StyleSheet.allow_motorways[StyleSheet.HEIGHT];
            id:motorways_yes; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}
        StdButton { source:StyleSheet.avoid_motorways[StyleSheet.SOURCE]; x:StyleSheet.avoid_motorways[StyleSheet.X]; y:StyleSheet.avoid_motorways[StyleSheet.Y]; width:StyleSheet.avoid_motorways[StyleSheet.WIDTH]; height:StyleSheet.avoid_motorways[StyleSheet.HEIGHT];
            id:motorways_no;  next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}

        StdButton { source:StyleSheet.back[StyleSheet.SOURCE]; x:StyleSheet.back[StyleSheet.X]; y:StyleSheet.back[StyleSheet.Y]; width:StyleSheet.back[StyleSheet.WIDTH]; height:StyleSheet.back[StyleSheet.HEIGHT];textColor:StyleSheet.backText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.backText[StyleSheet.PIXELSIZE];
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
