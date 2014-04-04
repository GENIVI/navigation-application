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
import QtQuick 1.0
import CustomType 1.0
import "Core"
import "Core/genivi.js" as Genivi;


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
		image:"navigation-settings-preference-menu-background";
//Important notice: x,y coordinates from the left/top origin, so take in account the header of 26 pixels high
		anchors { fill: parent; topMargin: parent.headlineHeight}
		Text {
                height:menu.hspc
				x:100; y:26;
                font.pixelSize: 25;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: Genivi.gettext("CostModel")
             }

		Text {
                height:menu.hspc
				x:330; y:26;
                font.pixelSize: 25;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: Genivi.gettext("RoutingPreferences")
             }

		Text {
                height:menu.hspc
				x:330; y:114;
                font.pixelSize: 32;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: Genivi.gettext("Ferries")
             }

        StdButton { source:"Core/images/allow.png"; x:560; y:99; width:50; height:60; id:ferries_yes; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_FERRY)}}
        StdButton { source:"Core/images/avoid.png"; x:610; y:99; width:50; height:60; id:ferries_no; next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_FERRY)}}

		Text {
                height:menu.hspc
				x:330; y:190;
                font.pixelSize: 32;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: Genivi.gettext("TollRoads")
             }

        StdButton { source:"Core/images/allow.png"; x:560; y:173; width:50; height:60; id:toll_roads_yes; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_TOLL_ROADS)}}
        StdButton { source:"Core/images/avoid.png"; x:610; y:173; width:50; height:60; id:toll_roads_no;  next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_TOLL_ROADS)}}

		Text {
                height:menu.hspc
				x:330; y:266;
                font.pixelSize: 32;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: Genivi.gettext("MotorWays")
             }

        StdButton { source:"Core/images/allow.png"; x:560; y:255; width:50; height:60; id:motorways_yes; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}
        StdButton { source:"Core/images/avoid.png"; x:610; y:255; width:50; height:60; id:motorways_no;  next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}

		StdButton { textColor:"black"; pixelSize:38 ; source:"Core/images/back.png"; x:600; y:374; width:180; height:60; id:back; text: Genivi.gettext("Back"); disabled:false; next:back; prev:back; page:"NavigationSettings"}

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
				var button=Qt.createQmlObject('import QtQuick 1.0; import "Core"; StdButton { }',content,'dynamic');
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
}
