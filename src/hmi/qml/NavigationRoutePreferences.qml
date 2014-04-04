/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationRoutePreferences.qml
*
* \brief This file is part of the FSA HMI.
*
* \author Martin Schaller <martin.schaller@it-schaller.de>
*
* \version 1.0
*
* This Source Code Form is subject to the terms of the
* Mozilla Public License (MPL), v. 2.0.
* If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/.
*
* For further information see http://www.genivi.org/.
*
* List of changes:
* 
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
	text: "RoutePreferences"
	hspc: 30

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

	DBusIf {
		id: dbusIf 
	}
	HMIGrid {
		id: content
		rows: 4
		columns: 2


        StdButton { id:ferries_yes; text:"Allow Ferries"; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_FERRY)}}
        StdButton { id:ferries_no; text:"Avoid Ferries"; next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_FERRY)}}
        StdButton { id:toll_roads_yes; text:"Allow Toll Roads"; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_TOLL_ROADS)}}
        StdButton { id:toll_roads_no; text:"Avoid Toll Roads"; next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_TOLL_ROADS)}}
        StdButton { id:motorways_yes; text:"Allow Motorways"; next:back; prev:back; explode:false; onClicked:{remove(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}
        StdButton { id:motorways_no; text:"Avoid Motorways"; next:back; prev:back; explode:false; onClicked:{add(Genivi.NAVIGATIONCORE_AVOID,Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}
		StdButton { id:back; text:"Back"; next:back; prev:back; page:"NavigationSettings" }
		Component.onCompleted: {
			update();
		}
	}
}
