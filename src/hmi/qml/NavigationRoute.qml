/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationRoute.qml
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
    text: Genivi.gettext("NavigationRoute")
	next: back
	prev: calculate
	property Item mapmatchedpositionPositionUpdateSignal;

	function latlon_to_map(latlon)
	{
		return [
			"uint16",Genivi.NAVIGATIONCORE_LATITUDE,"variant",["double",latlon['lat']],
			"uint16",Genivi.NAVIGATIONCORE_LONGITUDE,"variant",["double",latlon['lon']]
		];
	}

	function setLocation()
	{
        locationValue.text=Genivi.data['description'];
        positionValue.text=(Genivi.data['position'] ? Genivi.data['position']['description']:"");
        destinationValue.text=(Genivi.data['destination'] ? Genivi.data['destination']['description']:"");
	}

	function updateCurrentPosition()
	{
		var res=Genivi.nav_message(dbusIf,"MapMatchedPosition","GetPosition",["array",["uint16",Genivi.NAVIGATIONCORE_LATITUDE,"uint16",Genivi.NAVIGATIONCORE_LONGITUDE]]);
		if (res[0] == 'map') {
			var map=res[1];
			var ok=0;
			if (map[0] == 'uint16' && (map[1] == Genivi.NAVIGATIONCORE_LATITUDE || map[1] == Genivi.NAVIGATIONCORE_LONGITUDE) && map[2] == 'variant') {
				var variant=map[3];
				if (variant[0] == 'double' && variant[1] != '0') {
					ok++;
				}
		
			}
			if (map[4] == 'uint16' && (map[5] == Genivi.NAVIGATIONCORE_LATITUDE || map[5] == Genivi.NAVIGATIONCORE_LONGITUDE) && map[6] == 'variant') {
				var variant=map[7];
				if (variant[0] == 'double' && variant[1] != '0') {
					ok++;
				}
			}
			if (ok == 2 && Genivi.data['destination']) {
				calculate_curr.disabled=false;
			} else {
				calculate_curr.disabled=true;
			}
		}
	
	}
	
	function mapmatchedpositionPositionUpdate(args)
	{
		updateCurrentPosition();
	}

	function connectSignals()
	{
		mapmatchedpositionPositionUpdateSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.MapMatchedPosition","PositionUpdate",menu,"mapmatchedpositionPositionUpdate");
	}

	function disconnectSignals()
	{
	}

	DBusIf {
		id:dbusIf
	}
	
    HMIBgImage {
        image:"navigation-route-menu-background";
        anchors { fill: parent; topMargin: parent.headlineHeight}
        //Important notice: x,y coordinates from the left/top origin of the component
        //so take in account the header height and substract it

        Text {
            height:menu.hspc
            x:52; y:22;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("EnteredLocation")
        }

		Text {
            id:locationValue
			height:menu.hspc
            width: 600
            wrapMode: Text.WordWrap
            x:52; y:52;
            font.pixelSize: 32;
            style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true
		}

        Text {
            height:menu.hspc
            x:52; y:116;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("Position")
        }

        Text {
            id:positionValue
            height:menu.hspc
            width: 600
            wrapMode: Text.WordWrap
            x:52; y:150;
            font.pixelSize: 32;
            style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true
        }

        Text {
            height:menu.hspc
            x:52; y:210;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("Destination")
        }

        Text {
            id:destinationValue
            height:menu.hspc
            width: 600
            wrapMode: Text.WordWrap
            x:52; y:244;
            font.pixelSize: 32;
            style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true
        }

        StdButton { source:"Core/images/show-location-on-map.png"; x:660; y:38; width:100; height:60; id:show; disabled:false; next:destination; prev:back; explode:false;
            onClicked: {
                Genivi.data['show_position']=new Array();
                Genivi.data['show_position']['lat']=Genivi.data['lat'];
                Genivi.data['show_position']['lon']=Genivi.data['lon'];
                Genivi.data["mapback"]="NavigationRoute";
                disconnectSignals();
                pageOpen("NavigationBrowseMap");
            }
        }

        StdButton { source:"Core/images/set-as-position.png"; x:660; y:142; width:100; height:60; id:position; disabled:false; next:calculate; prev:destination; explode:false;
            onClicked: {
                Genivi.data['position']=new Array();
                Genivi.data['position']['lat']=Genivi.data['lat'];
                Genivi.data['position']['lon']=Genivi.data['lon'];
                Genivi.data['position']['description']=Genivi.data['description'];
                setLocation();
                if (Genivi.data['destination'])
                    calculate.disabled=false;
            }
        }

        StdButton { source:"Core/images/set-as-destination.png"; x:660; y:246; width:100; height:60; id:destination; disabled:false; next:position; prev:show; explode:false;
             onClicked: {
                Genivi.data['destination']=new Array();
                Genivi.data['destination']['lat']=Genivi.data['lat'];
                Genivi.data['destination']['lon']=Genivi.data['lon'];
                Genivi.data['destination']['description']=Genivi.data['description'];
                setLocation();
                if (Genivi.data['position'])
                    calculate.disabled=false;
                updateCurrentPosition();
            }
        }

        StdButton { textColor:"black"; pixelSize:38; text: Genivi.gettext("Route"); source:"Core/images/route.png"; x:20; y:374; width:180; height:60; id:calculate; explode:false;
            onClicked: {
                var dest=latlon_to_map(Genivi.data['destination']);
                var pos=latlon_to_map(Genivi.data['position']);
                Genivi.routing_message(dbusIf,"SetWaypoints",["boolean",false,"array",["map",pos,"map",dest]]);
                Genivi.data['calculate_route']=true;
                disconnectSignals();
                Genivi.data['lat']='';
                Genivi.data['lon']='';
                pageOpen("NavigationCalculatedRoute");
            }
            disabled:!(Genivi.data['position'] && Genivi.data['destination']); next:calculate_curr; prev:position
        }

        StdButton { textColor:"black"; pixelSize:38; text: Genivi.gettext("GoTo"); source:"Core/images/route.png"; x:224; y:374; width:180; height:60; id:calculate_curr; explode:false;
            onClicked: {
                var dest=latlon_to_map(Genivi.data['destination']);
                Genivi.routing_message(dbusIf,"SetWaypoints",["boolean",true,"array",["map",dest]]);
                Genivi.data['calculate_route']=true;
                disconnectSignals();
                Genivi.data['lat']='';
                Genivi.data['lon']='';
                pageOpen("NavigationCalculatedRoute");
            }
            disabled:true; next:back; prev:calculate
        }

        StdButton { textColor:"black"; pixelSize:38 ; source:"Core/images/back.png"; x:600; y:374; width:180; height:60; id:back; text: Genivi.gettext("Back"); disabled:false; next:show; prev:calculate_curr;
            onClicked: {
                disconnectSignals();
                Genivi.data['lat']='';
                Genivi.data['lon']='';
                pageOpen("NavigationSearch");
            }
        }

        Component.onCompleted: {
            setLocation();
            updateCurrentPosition();
            connectSignals();
        }
	}
}
