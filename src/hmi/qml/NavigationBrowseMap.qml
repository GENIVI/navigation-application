/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
*
* \file NavigationBrowseMap.qml
*
* \brief This file is part of the navigation hmi.
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
    text: Genivi.gettext("NavigationBrowseMap")
	next: up
	prev: menub
	property Item guidanceWaypointReachedSignal;
	property Item guidanceManeuverChangedSignal;
    property Item guidancePositionOnRouteChangedSignal;
	property Item mapmatchedpositionPositionUpdateSignal;
	property Item mapmatchedpositionAddressUpdateSignal;
	property Item fuelStopAdvisorSignal;
	property string guidance: "No guidance";
	property string maneuver: "No maneuver";
	property string maneuver_distance: "";
	property string totaldistance: "";
	property string totaltime: "";
	property bool north:false;
	

	DBusIf {
		id:dbusIf
	}

	function guidanceManeuverChanged(args)
	{
		// TODO: Create possibility to poll information?
		// console.log("guidanceManeuverChanged");
		// Genivi.dump("",args);
		guidance=Genivi.Maneuver[args[1]];
	}

	function guidanceWaypointReached(args)
	{
		// console.log("guidanceWaypointReached");
		// Genivi.dump("",args);
		if (args[2]) {
			guidance="Destination reached";
		} else {
			guidance="Waypoint reached";
		}

	}

    function guidancePositionOnRouteChanged(args)
	{
		updateGuidance();
	}
	
	function mapmatchedpositionPositionUpdate(args)
	{
		var res=Genivi.nav_message(dbusIf,"MapMatchedPosition","GetPosition",["array",["uint16",Genivi.NAVIGATIONCORE_SPEED]]);
		if (res[0] == "map" && res[1][0] == "uint16" && res[1][1] == Genivi.NAVIGATIONCORE_SPEED && res[1][2] == "variant" && res[1][3][0] == "double") {
			speed.text=res[1][3][1]+"\nkm/h";
		} else {
			console.log("Unexpected result from GetPosition:");
			Genivi.dump("",res);
		}
	}

	function updateAddress()
	{
		var res=Genivi.nav_message(dbusIf,"MapMatchedPosition","GetAddress",["array",["uint16",Genivi.NAVIGATIONCORE_STREET]]);
		if (res[0] == "map" && res[1][0] == "uint16" && res[1][1] == Genivi.NAVIGATIONCORE_STREET && res[1][2] == "variant" && res[1][3][0] == "string") {
            menu.text=Genivi.gettext("NavigationCurrentStreet") + ":"+res[1][3][1];
		} else {
            menu.text=Genivi.gettext("NavigationBrowseMap");
		}
	}

	function mapmatchedpositionAddressUpdate(args)
	{
		updateAddress();
	}

	function showZoom()
	{
		var res=Genivi.mapviewercontrol_message(dbusIf, "GetMapViewScale", []);
		if (res[0] == "uint8" && res[2] == "uint16") {
			var text=res[1];
			if (res[3])
				text+="*";
			zoomlevel.text=text;
			console.log("zoomlevel " + text);
		} else {
			console.log("Unexpected Result from GetMapViewScale:");
			Genivi.dump("",res);
		}
	}

	function fuelStopAdvisorWarning(args)
	{
		fuel.text="F";
	}

	function connectSignals()
        {
		guidanceWaypointReachedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.Guidance","WaypointReached",menu,"guidanceWaypointReached");
		guidanceManeuverChangedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.Guidance","ManeuverChanged",menu,"guidanceManeuverChanged");
        guidancePositionOnRouteChangedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.Guidance","PositionOnRouteChanged",menu,"guidancePositionOnRouteChanged");
		mapmatchedpositionPositionUpdateSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.MapMatchedPosition","PositionUpdate",menu,"mapmatchedpositionPositionUpdate");
		mapmatchedpositionAddressUpdateSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.MapMatchedPosition","AddressUpdate",menu,"mapmatchedpositionAddressUpdate");
		fuelStopAdvisorSignal=dbusIf.connect("","/org/genivi/demonstrator/FuelStopAdvisor","org.genivi.demonstrator.FuelStopAdvisor","FuelStopAdvisorWarning",menu,"fuelStopAdvisorWarning");
        }

        function disconnectSignals()
        {
		guidanceWaypointReachedSignal.destroy();
		guidanceManeuverChangedSignal.destroy();
        guidancePositionOnRouteChangedSignal.destroy();
		mapmatchedpositionPositionUpdateSignal.destroy();
		mapmatchedpositionAddressUpdateSignal.destroy();
		fuelStopAdvisorSignal.destroy();
		Genivi.fuel_stop_advisor_message(dbusIf,"SetFuelAdvisorSettings",["boolean",0,"uint8",0]);
		Genivi.fuel_stop_advisor_message(dbusIf,"SetRouteHandle","uint32",0);
	}

	function showSurfaces()
	{
		Genivi.lm_message(dbusIf,"ServiceConnect",["uint32",dbusIf.pid()]);
		if (Genivi.g_map_handle2) {
			Genivi.lm_message(dbusIf,"SetSurfaceDestinationRegion",["uint32",2000+Genivi.g_map_handle[1],"uint32",map.x,"uint32",map.y,"uint32",map.width/2,"uint32",map.height]);
			Genivi.lm_message(dbusIf,"SetSurfaceSourceRegion",["uint32",2000+Genivi.g_map_handle[1],"uint32",0,"uint32",0,"uint32",map.width/2,"uint32",map.height]);
			Genivi.lm_message(dbusIf,"SetSurfaceDestinationRegion",["uint32",2000+Genivi.g_map_handle2[1],"uint32",map.x+map.width/2,"uint32",map.y,"uint32",map.width/2,"uint32",map.height]);
			Genivi.lm_message(dbusIf,"SetSurfaceSourceRegion",["uint32",2000+Genivi.g_map_handle2[1],"uint32",0,"uint32",0,"uint32",map.width/2,"uint32",map.height]);
			Genivi.lm_message(dbusIf,"SetSurfaceVisibility",["uint32",2000+Genivi.g_map_handle[1],"boolean",true]);
			Genivi.lm_message(dbusIf,"SetSurfaceVisibility",["uint32",2000+Genivi.g_map_handle2[1],"boolean",true]);
		} else {
			Genivi.lm_message(dbusIf,"SetSurfaceDestinationRegion",["uint32",2000+Genivi.g_map_handle[1],"uint32",map.x,"uint32",map.y,"uint32",map.width,"uint32",map.height]);
			Genivi.lm_message(dbusIf,"SetSurfaceSourceRegion",["uint32",2000+Genivi.g_map_handle[1],"uint32",0,"uint32",0,"uint32",map.width,"uint32",map.height]);
			Genivi.lm_message(dbusIf,"SetSurfaceVisibility",["uint32",2000+Genivi.g_map_handle[1],"boolean",true]);
		}
		Genivi.lm_message(dbusIf,"CommitChanges",[]);
		Genivi.lm_message(dbusIf,"ServiceDisconnect",["uint32",dbusIf.pid()]);
	}

	function hideSurfaces()
	{
		Genivi.lm_message(dbusIf,"ServiceConnect",["uint32",dbusIf.pid()]);
		if (Genivi.g_map_handle2) {
			Genivi.lm_message(dbusIf,"SetSurfaceVisibility",["uint32",2000+Genivi.g_map_handle2[1],"boolean",false]);
		}
		Genivi.lm_message(dbusIf,"SetSurfaceVisibility",["uint32",2000+Genivi.g_map_handle[1],"boolean",false]);
		Genivi.lm_message(dbusIf,"CommitChanges",[]);
		Genivi.lm_message(dbusIf,"ServiceDisconnect",["uint32",dbusIf.pid()]);
	}


	function updateMapViewer()
	{
		var res=Genivi.mapviewercontrol_message(dbusIf,"GetMapViewPerspective",[]);
		if (res[0] == "uint16") {
			if (res[1] == Genivi.MAPVIEWER_2D) {
				perspective.text="3d";
			} else {
				perspective.text="2d";
			}
		} else {
			console.log("Unexpected result from GetMapViewPerspective:");
			Genivi.dump("",res);
		}
		var res=Genivi.mapviewercontrol_message(dbusIf,"GetDisplayedRoutes",[]);
		if (res[0] == "array" && res[1] && res[1].length) {
			split.disabled=false;
		} else {
			split.disabled=true;
		}
		if (Genivi.g_map_handle2) {
			split.text="Join";
		} else {
			split.text="Split";
		}
	}

	function routeOverview()
	{
		if (!split.disabled) {
			disconnectSignals();
			hideSurfaces();
			pageOpen("NavigationCalculatedRoute");
		}
	}

	function updateDayNight()
	{
		var res=Genivi.mapviewercontrol_message(dbusIf, "GetMapViewTheme", []);
		if (res[0] == "uint16" && res[1] == Genivi.MAPVIEWER_THEME_1) {
			daynight.text="Night";
		} else {
			daynight.text="Day";
		}
	}

	function toggleDayNight()
	{
		var res=Genivi.mapviewercontrol_message(dbusIf, "GetMapViewTheme", []);
		if (res[0] == "uint16" && res[1] == Genivi.MAPVIEWER_THEME_1) {
			Genivi.mapviewercontrol_message(dbusIf,"SetMapViewTheme",["uint16",Genivi.MAPVIEWER_THEME_2]);
			if (Genivi.g_map_handle2) {
				Genivi.mapviewercontrol_message2(dbusIf,"SetMapViewTheme",["uint16",Genivi.MAPVIEWER_THEME_2]);
			}	
			daynight.text="Day";
		} else {
			Genivi.mapviewercontrol_message(dbusIf,"SetMapViewTheme",["uint16",Genivi.MAPVIEWER_THEME_1]);
			if (Genivi.g_map_handle2) {
				Genivi.mapviewercontrol_message2(dbusIf,"SetMapViewTheme",["uint16",Genivi.MAPVIEWER_THEME_1]);
			}
			daynight.text="Night";
		}
	}

	function togglePerspective()
	{
		if (perspective.text == "2d") {
			Genivi.mapviewercontrol_message(dbusIf,"SetMapViewPerspective",["uint16",Genivi.MAPVIEWER_2D]);
		} else {
			Genivi.mapviewercontrol_message(dbusIf,"SetMapViewPerspective",["uint16",Genivi.MAPVIEWER_3D]);
		}
		updateMapViewer();
	}

	function toggleSplit()
	{
		hideSurfaces();
		var res=Genivi.mapviewercontrol_message(dbusIf,"GetDisplayedRoutes",[]);
		var res3=Genivi.mapviewercontrol_message(dbusIf, "GetMapViewTheme", []);
		if (split.text == "Split") {
			Genivi.map_handle_clear(dbusIf);
			Genivi.map_handle2(dbusIf,map.width/2,map.height,Genivi.MAPVIEWER_MAIN_MAP);
			Genivi.map_handle(dbusIf,map.width/2,map.height,Genivi.MAPVIEWER_MAIN_MAP);
			if (res[0] == "array" && res[1] && res[1].length) {
                var res2=Genivi.routing_message_get(dbusIf, "GetRouteBoundingBox", []);
				if (res2[0] == "structure") {
					Genivi.mapviewercontrol_message2(dbusIf, "SetMapViewBoundingBox", res2);
				} else {
					console.log("Unexpected result from GetRouteBoundingBox:");
					Genivi.dump("",res2);
				}
			}
			if (res3[0] == "uint16") {
				Genivi.mapviewercontrol_message(dbusIf, "SetMapViewTheme", res3);
				Genivi.mapviewercontrol_message2(dbusIf, "SetMapViewTheme", res3);
			}
			Genivi.mapviewercontrol_message(dbusIf, "SetFollowCarMode", ["boolean",true]);
		} else {
			Genivi.map_handle_clear2(dbusIf);
			Genivi.map_handle_clear(dbusIf);
			Genivi.map_handle(dbusIf,map.width,map.height,Genivi.MAPVIEWER_MAIN_MAP);
			if (res3[0] == "uint16") {
				Genivi.mapviewercontrol_message(dbusIf, "SetMapViewTheme", res3);
			}
			Genivi.mapviewercontrol_message(dbusIf, "SetFollowCarMode", ["boolean",true]);
		}
		if (res[0] == "array" && res[1] && res[1].length) {
			for (var i = 0 ; i < res[1].length ; i+=2) {
				Genivi.mapviewercontrol_message(dbusIf, "DisplayRoute", res[1][i+1]);
				if (split.text == "Split") {
					Genivi.mapviewercontrol_message2(dbusIf, "DisplayRoute", res[1][i+1]);
				}
			}
		}
		showSurfaces();
		updateMapViewer();
	}

	function disableSplit()
	{
		if (Genivi.g_map_handle2) {
			toggleSplit();
		}
	}

	function toggleOrientation()
	{
		north=!north;
		if (north) {
			Genivi.mapviewercontrol_message(dbusIf, "SetCameraHeadingAngle", ["int32",0]);
			orientation.text="D";
		} else {
			Genivi.mapviewercontrol_message(dbusIf, "SetCameraHeadingTrackUp", []);
			orientation.text="N";
		}
	}

	function updateGuidance()
	{
        var res=Genivi.guidance_message_get(dbusIf,"GetGuidanceStatus",[]);
		if (res[0] != "uint16") {
			console.log("Unexpected result from GetGuidanceStatus:");
			Genivi.dump("",res);
			return;
		}
		if (res[1] == Genivi.NAVIGATIONCORE_INACTIVE) {
			stop.disabled=true;
			guidance="No guidance";
			maneuver="No maneuver";
			maneuver_distance="";
			totaldistance="";
			totaltime="";
			return;
		} else {
			stop.disabled=false;
		}

        var res=Genivi.guidance_message_get(dbusIf,"GetManeuversList",["uint16",1,"uint32",0]);

        Genivi.dump("GetManeuversList",res);

        if (res[0] == "uint16" && res[2] == "array") {
            var array=res[3];
            for (var i = 0 ; i < array.length ; i+=2) {
                if (array[i] == "structure" && array[i+1][0] == "string" && array[i+1][2] == "string" && array[i+1][4] == "uint16" && array[i+1][6] == "uint16" && array[i+1][8] == "uint32" && array[i+1][10] == "array") {
                    var structure=array[i+1];
                    var subarray=structure[11];
                    for (var j = 0 ; j < subarray.length ; j+=2) {
                        //multiple maneuvers are not managed !
                        if (subarray[j] == "structure" && subarray[j+1][0] == "uint32" && subarray[j+1][2] == "uint32" && subarray[j+1][4] == "int32" && subarray[j+1][6] == "uint16" && subarray[j+1][8] == "array") {
                            var substructure=subarray[j+1];
                            var subsubarray=subarray[j+1][9];
                            if (subsubarray[0] == "structure" && subsubarray[1][0] == "uint16")
                            {
                               if (subsubarray[1][1] == Genivi.NAVIGATIONCORE_DIRECTION && subsubarray[1][2] == "variant" && subsubarray[1][3][0] == "uint16")
                               {
                                   stop.disabled=false;
                                   maneuver=Genivi.ManeuverType[subarray[j+1][7]]+":"+Genivi.ManeuverDirection[subsubarray[1][3][1]];
                                   maneuver_distance=Genivi.distance(substructure[1])+" "+structure[3];

                               }
                            }
                        }
                    }
                }
            }
            console.log("maneuver " + maneuver);
            console.log("maneuver_distance " + maneuver_distance);

        } else {
            console.log("Unexpected result from GetManeuversList");
            Genivi.dump("",res);
        }

        res=Genivi.guidance_message_get(dbusIf,"GetDestinationInformation",[]);

        if (res[0] == "uint32")
        {
            totaldistance = Genivi.distance(res[1]);
        }
        else
        {
            console.log("Unexpected result from GetDestinationInformation");
            Genivi.dump("",res);
        }
        if (res[2] == "uint32")
        {
            totaltime = Genivi.time(res[3]);
        }
        else
        {
            console.log("Unexpected result from GetDestinationInformation");
            Genivi.dump("",res);
        }

    }

	function stopGuidance()
	{
		Genivi.guidance_message(dbusIf,"StopGuidance",[]);
		updateGuidance();
	}

	Row {
		id:content
		y:30;
		x:menu.wspc/2;
		height:content.h
		property real w: menu.w(7);
		property real h: menu.h(4);
        property real panX: 40 //delta in pixel for x panning
        property real panY: 40 //delta in pixel for y panning
        spacing: menu.wspc/3;

		StdButton { id:up; text:"Up"; explode:false; next:left; prev:daynight
                onPressed: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["uint16",Genivi.MAPVIEWER_PAN_START,"array",["structure",["uint16",map.width/2,"uint16",map.height/2]]]);}
                onReleased: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["uint16",Genivi.MAPVIEWER_PAN_END,"array",["structure",["uint16",map.width/2,"uint16",map.height/2 + content.panY]]]);}
		}
		StdButton { id:left; text:"Left"; explode:false; next:right; prev:up
                onPressed: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["uint16",Genivi.MAPVIEWER_PAN_START,"array",["structure",["uint16",map.width/2,"uint16",map.height/2]]]);}
                onReleased: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["uint16",Genivi.MAPVIEWER_PAN_END,"array",["structure",["uint16",map.width/2 + content.panX,"uint16",map.height/2]]]);}
		}
		StdButton { id:right; text:"Right"; explode:false; next:down; prev:left
                onPressed: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["uint16",Genivi.MAPVIEWER_PAN_START,"array",["structure",["uint16",map.width/2,"uint16",map.height/2]]]);}
                onReleased: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["uint16",Genivi.MAPVIEWER_PAN_END,"array",["structure",["uint16",map.width/2 - content.panX,"uint16",map.height/2]]]);}
		}
		StdButton { id:down; text:"Down"; explode:false; next:zoom_in; prev:right
                onPressed: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["uint16",Genivi.MAPVIEWER_PAN_START,"array",["structure",["uint16",map.width/2,"uint16",map.height/2]]]);}
                onReleased: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["uint16",Genivi.MAPVIEWER_PAN_END,"array",["structure",["uint16",map.width/2,"uint16",map.height/2 - content.panY]]]);}
		}
		StdButton { id:zoom_in; text:"+"; explode:false; next:zoom_out; prev:down
			    onClicked: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewScaleByDelta", ["int16",1]);showZoom();}
		}
		StdButton { id:zoom_out; text:"-"; explode:false; next:perspective; prev:zoom_in
			    onClicked: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewScaleByDelta", ["int16",-1]);showZoom();}
		}
		StdButton { id:perspective; text:"3d"; explode:false; next:split; prev:zoom_out
			    onClicked: {togglePerspective();}
		}
		StdButton { id:split; text:"Split"; explode:false; next:orientation; prev:perspective
			    onClicked: {toggleSplit();}
		}
		StdButton { id:orientation; text:"N"; explode:false; next:camera; prev:split
			    onClicked: {toggleOrientation();}
		}
		StdButton { id:camera; text:"C"; explode:false; next:back; prev:orientation
			    onClicked: {
				disableSplit();
				disconnectSignals();
				hideSurfaces();
				pageOpen("CameraSettings");
			    }
		}
		Rectangle {
			width:speed.width+20
			height:content.h
			color:"#000000"
			opacity: 0.8
			radius: 10
			Text { 
				anchors { left:parent.left; leftMargin: 10; top:parent.top; topMargin: 2 }
				id:speed
				font.pixelSize: 18;
				style: Text.Sunken
				color: "white"
				styleColor: "black"
				smooth: true
				text: "0\nkm/h"
			}
		}
		Rectangle {
			width:zoomlevel.width+20
			height:content.h
			color:"#000000"
			opacity: 0.8
			radius: 10

			Text { 
				anchors { left:parent.left; leftMargin: 10; top:parent.top; topMargin: 2 }
				id:zoomlevel
				font.pixelSize: 18;
				style: Text.Sunken
				color: "white"
				styleColor: "black"
				smooth: true
			}
		}
	}
	Rectangle {
		id:map
		y:content.y+content.height+4
		height:menu.height-y-bottom.height-8
		width:menu.width
		color:"#ffff7e"
	}
	Row {
		id:bottom
		y:menu.height-height-4
		x:menu.wspc/2;
		height:content.h
		spacing:menu.wspc/4

		StdButton { id:back; text:"Back"; next:menub; prev:camera
			onClicked: {
				disconnectSignals();
				hideSurfaces();
				pageOpen(Genivi.data["mapback"]);
			}
		}
		StdButton { id:menub; text:"Menu"; next:stop; prev:back
			onClicked: {
				disconnectSignals();
				hideSurfaces();
				pageOpen("MainMenu");
			}
		}
		StdButton { id:stop; text:"Stop"; explode:false; next:daynight; prev:menub
			    onClicked: {stopGuidance();}
			    disabled: true
		}

		StdButton { id:daynight; text:""; explode:false; next:up; prev:stop
			onClicked: {
				toggleDayNight();
			}
		}
		
		Rectangle {
			width:totalt.width+20
			height:content.h
			color:"#000000"
			opacity: 0.8
			radius: 10
			MouseArea {
				anchors.fill: parent
				onClicked: {
					routeOverview();
                        	}
                	}
			Text { 
				anchors { left:parent.left; leftMargin: 10; top:parent.top; topMargin: 2 }
				id:totalt
				text: "TotalTime:\n"+menu.totaltime
				font.pixelSize: 18;
				style: Text.Sunken
				color: "white"
				styleColor: "black"
				smooth: true
			}
		}
		Rectangle {
			width:totaldist.width+20
			height:content.h
			color:"#000000"
			opacity: 0.8
			radius: 10
			MouseArea {
				anchors.fill: parent
				onClicked: {
					routeOverview();
                        	}
                	}
			Text { 
				anchors { left:parent.left; leftMargin: 10; top:parent.top; topMargin: 2 }
				id:totaldist
				text: "TotalDistance:\n"+menu.totaldistance
				font.pixelSize: 18;
				style: Text.Sunken
				color: "white"
				styleColor: "black"
				smooth: true
			}
		}
		Rectangle {
			width:nextturn.width+20
			height:content.h
			color:"#000000"
			opacity: 0.8
			radius: 10
			MouseArea {
				anchors.fill: parent
				onClicked: {
					var res=Genivi.guidance_message(dbusIf,"GetGuidanceStatus",[]);
					if (res[0] == "uint16") {
						if (res[1] != Genivi.NAVIGATIONCORE_INACTIVE) {
							disconnectSignals();
							hideSurfaces();
							pageOpen("NavigationManeuversList");
						}
					}
                        	}
                	}
			Text { 
				anchors { left:parent.left; leftMargin: 10; top:parent.top; topMargin: 2 }
				id:nextturn
				text: menu.guidance+"\n"+menu.maneuver+"\n"+menu.maneuver_distance;
				font.pixelSize: 12;
				style: Text.Sunken
				color: "white"
				styleColor: "black"
				smooth: true
			}
		}
		Rectangle {
			width:20
			height:content.h
			color:"#000000"
			opacity: 0.8
			radius: 10
			MouseArea {
				anchors.fill: parent
				onClicked: {
					disconnectSignals();
					hideSurfaces();
					pageOpen("POI");
                        	}
                	}
			Text { 
				anchors { left:parent.left; leftMargin: 10; top:parent.top; topMargin: 2 }
				id:fuel
				text:""
				font.pixelSize: 20;
				style: Text.Sunken
				color: "white"
				styleColor: "black"
				smooth: true
			}
		}
	}
	Component.onCompleted: {
		Genivi.map_handle(dbusIf,map.width,map.height,Genivi.MAPVIEWER_MAIN_MAP);
		showSurfaces();
		if (Genivi.data['show_route_handle']) {
			Genivi.mapviewercontrol_message(dbusIf, "DisplayRoute", Genivi.data['show_route_handle'].concat("boolean",false));
			delete(Genivi.data['show_route_handle']);
		}
		if (Genivi.data['zoom_route_handle']) {
			var res=Genivi.nav_message(dbusIf, "Routing", "GetRouteBoundingBox", Genivi.nav_session(dbusIf).concat(Genivi.data['zoom_route_handle']));
			if (res[0] == "structure") {
				Genivi.mapviewercontrol_message(dbusIf, "SetMapViewBoundingBox", res);
			} else {
				Console.log("Unexpected result from GetRouteBoundingBox:");
				Genivi.dump("",res);
			}
			delete(Genivi.data['zoom_route_handle']);
		}
		if (Genivi.data['show_position']) {
			Genivi.mapviewercontrol_message(dbusIf, "SetFollowCarMode", ["boolean",false]);
			Genivi.mapviewercontrol_message(dbusIf, "SetTargetPoint", ["structure",[
				"double",Genivi.data['show_position']['lat'],
				"double",Genivi.data['show_position']['lon'],
				"int32",Genivi.data['show_position']['alt']
				]]
			);
			delete(Genivi.data['show_position']);
		}
		if (Genivi.data['show_current_position']) {
			Genivi.mapviewercontrol_message(dbusIf, "SetFollowCarMode", ["boolean",true]);
			delete(Genivi.data['show_current_position']);
		}
		connectSignals();
		updateGuidance();
		updateMapViewer();
		showZoom();
		updateAddress();
		updateDayNight();
		if (Genivi.g_routing_handle) {
			Genivi.fuel_stop_advisor_message(dbusIf,"SetRouteHandle",Genivi.g_routing_handle);
		} else {
			Genivi.fuel_stop_advisor_message(dbusIf,"SetRouteHandle","uint32",0);
		}
		Genivi.fuel_stop_advisor_message(dbusIf,"SetFuelAdvisorSettings",["boolean",1,"uint8",50]);
	}
}
