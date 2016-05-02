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
* \version 
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
import QtQuick 2.1 
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/navigation-browse-map-css.js" as StyleSheetMap;
import "Core/style-sheets/navigation-browse-map-bottom-css.js" as StyleSheetBottom
import "Core/style-sheets/navigation-browse-map-route-css.js" as StyleSheetRoute
import "Core/style-sheets/navigation-browse-map-guidance-css.js" as StyleSheetGuidance
import "Core/style-sheets/navigation-browse-map-scroll-css.js" as StyleSheetScroll
import "Core/style-sheets/navigation-browse-map-simulation-css.js" as StyleSheetSimulation
import "Core/style-sheets/navigation-browse-map-top-css.js" as StyleSheetTop

import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    property string pagefile:"NavigationBrowseMap"
    next: scrollup
	prev: menub
	property Item guidanceWaypointReachedSignal;
	property Item guidanceManeuverChangedSignal;
    property Item guidancePositionOnRouteChangedSignal;
	property Item mapmatchedpositionPositionUpdateSignal;
	property Item mapmatchedpositionAddressUpdateSignal;
    property Item simulationStatusChangedSignal;
    property Item simulationSpeedChangedSignal;
	property Item fuelStopAdvisorSignal;
	property bool north:false;
    property int speedValueSent: 0;

	DBusIf {
		id:dbusIf
	}

	function guidanceManeuverChanged(args)
	{
		// TODO: Create possibility to poll information?
		// console.log("guidanceManeuverChanged");
		// Genivi.dump("",args);
        maneuverAdvice.text=Genivi.Maneuver[args[1]];
	}

	function guidanceWaypointReached(args)
	{
		// console.log("guidanceWaypointReached");
		// Genivi.dump("",args);
		if (args[2]) {
            maneuverAdvice.text="Destination reached";
		} else {
            maneuverAdvice.text="Waypoint reached";
		}

	}

    function guidancePositionOnRouteChanged(args)
	{
		updateGuidance();
	}
	
	function mapmatchedpositionPositionUpdate(args)
	{
        var res=Genivi.mapmatchedposition_GetPosition(dbusIf);
        for (var i=0;i<res[1].length;i+=4){
            if (res[1][i+1]== Genivi.NAVIGATIONCORE_SPEED){
                vehicleSpeedValue.text=res[1][i+3][3][1];
            }
        }
	}

    function simulationSpeedChanged(args)
    {
        if (args[1] == 0) {
            speedValue.text="0";
            speedValueSent=0;
        }
        if (args[1] == 1) {
            speedValue.text="1/4";
            speedValueSent=1;
        }
        if (args[1] == 2) {
            speedValue.text="1/2";
            speedValueSent=2;
        }
        if (args[1] == 4) {
            speedValue.text="1";
            speedValueSent=3;
        }
        if (args[1] == 8) {
            speedValue.text="2";
            speedValueSent=4;
        }
        if (args[1] == 16) {
            speedValue.text="4";
            speedValueSent=5;
        }
        if (args[1] == 32) {
            speedValue.text="8";
            speedValueSent=6;
        }
        if (args[1] == 64) {
            speedValue.text="16";
            speedValueSent=7;
        }
    }

    function simulationStatusChanged(args)
    {
        if (args[1] != Genivi.NAVIGATIONCORE_SIMULATION_STATUS_NO_SIMULATION)
        {
            on_off.setState("ON");
            if (args[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_PAUSED || args[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_FIXED_POSITION)
            {
                simu_mode.setState("PAUSE");
            }
            else
            {
                if (args[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_RUNNING)
                {
                    simu_mode.setState("PLAY");
                }
            }
        }
        else
        {
            on_off.setState("OFF");
            simu_mode.setState("FREE");
        }
}

    function updateSimulation()
    {
        var res=Genivi.mapmatchedposition_GetSimulationStatus(dbusIf);
        if (res[1] != Genivi.NAVIGATIONCORE_SIMULATION_STATUS_NO_SIMULATION)
        {
            on_off.setState("ON");
            if (res[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_PAUSED || res[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_FIXED_POSITION)
            {
                simu_mode.setState("PAUSE");
            }
            else
            {
                if (res[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_RUNNING)
                {
                    simu_mode.setState("PLAY");
                }
            }
        }
        else
        {
            on_off.setState("OFF");
            simu_mode.setState("FREE");
        }

        var res1=Genivi.mapmatchedposition_GetSimulationSpeed(dbusIf);
        if (res1[1] == 0) {
            speedValue.text="0";
            speedValueSent=0;
        }
        if (res1[1] == 1) {
            speedValue.text="1/4";
            speedValueSent=1;
        }
        if (res1[1] == 2) {
            speedValue.text="1/2";
            speedValueSent=2;
        }
        if (res1[1] == 4) {
            speedValue.text="1";
            speedValueSent=3;
        }
        if (res1[1] == 8) {
            speedValue.text="2";
            speedValueSent=4;
        }
        if (res1[1] == 16) {
            speedValue.text="4";
            speedValueSent=5;
        }
        if (res1[1] == 32) {
            speedValue.text="8";
            speedValueSent=6;
        }
        if (res1[1] == 64) {
            speedValue.text="16";
            speedValueSent=7;
        }
    }

    function getDBusSpeedValue(value)
    {
        var returnValue;
        switch (value)
        {
            case 0:
                returnValue = 0;
            break;
            case 1:
                returnValue = 1;
            break;
            case 2:
                returnValue = 2;
            break;
            case 3:
                returnValue = 4;
            break;
            case 4:
                returnValue = 8;
            break;
            case 5:
                returnValue = 16;
            break;
            case 6:
                returnValue = 32;
            break;
            case 7:
                returnValue = 64;
            break;
            default:
                returnValue = 0;
            break;
        }
        return	returnValue;
    }

	function updateAddress()
	{
        var res=Genivi.mapmatchedposition_GetAddress(dbusIf);
        if (res[1][1] == Genivi.NAVIGATIONCORE_STREET) {
            currentroad.text=res[1][3][3][1];
		} else {
            currentroad.text="";
		}
	}

	function mapmatchedpositionAddressUpdate(args)
	{
		updateAddress();
	}

	function showZoom()
	{
        var res=Genivi.mapviewer_GetMapViewScale(dbusIf);
        var text=res[1];
        if (res[3])
            text+="*";
        zoomlevel.text=text;
	}

	function fuelStopAdvisorWarning(args)
	{
        if (args[1] == 1)
        {
            fsamessageText.text=Genivi.gettext("FSAWarning");
            select_search_for_refill_in_top.visible=true;
        }
        else
        {
            fsamessageText.text=" ";
            select_search_for_refill_in_top.visible=false;
         }
	}

	function connectSignals()
    {
        guidanceWaypointReachedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.Guidance","WaypointReached",menu,"guidanceWaypointReached");
        guidanceManeuverChangedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.Guidance","ManeuverChanged",menu,"guidanceManeuverChanged");
        guidancePositionOnRouteChangedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.Guidance","PositionOnRouteChanged",menu,"guidancePositionOnRouteChanged");
        simulationStatusChangedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.MapMatchedPosition","SimulationStatusChanged",menu,"simulationStatusChanged");
        simulationSpeedChangedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.MapMatchedPosition","SimulationSpeedChanged",menu,"simulationSpeedChanged");
        mapmatchedpositionPositionUpdateSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.MapMatchedPosition","PositionUpdate",menu,"mapmatchedpositionPositionUpdate");
        mapmatchedpositionAddressUpdateSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.MapMatchedPosition","AddressUpdate",menu,"mapmatchedpositionAddressUpdate");
        fuelStopAdvisorSignal=dbusIf.connect("","/org/genivi/demonstrator/FuelStopAdvisor","org.genivi.demonstrator.FuelStopAdvisor","FuelStopAdvisorWarning",menu,"fuelStopAdvisorWarning");
    }

    function disconnectSignals()
    {
        guidanceWaypointReachedSignal.destroy();
        guidanceManeuverChangedSignal.destroy();
        guidancePositionOnRouteChangedSignal.destroy();
        simulationStatusChangedSignal.destroy();
        simulationSpeedChangedSignal.destroy();
        mapmatchedpositionPositionUpdateSignal.destroy();
        mapmatchedpositionAddressUpdateSignal.destroy();
        fuelStopAdvisorSignal.destroy();
    }

	function routeOverview()
	{
        disconnectSignals();
        entryMenu("NavigationCalculatedRoute",menu);
	}

	function toggleOrientation()
	{
		north=!north;
		if (north) {
			Genivi.mapviewercontrol_message(dbusIf, "SetCameraHeadingAngle", ["int32",0]);
            orientation.setState("D");
		} else {
			Genivi.mapviewercontrol_message(dbusIf, "SetCameraHeadingTrackUp", []);
            orientation.setState("N");
		}
	}

	function updateGuidance()
	{
        var res=Genivi.guidance_GetGuidanceStatus(dbusIf);
		if (res[1] == Genivi.NAVIGATIONCORE_INACTIVE) {
            guidanceStatus.setState("OFF");
            Genivi.guidance_activated = false;
            //Guidance inactive, so inform the trip computer
            Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,0,0);
            maneuverAdvice.text=Genivi.gettext("NoGuidance");
            maneuverIcon.source=StyleSheetGuidance.maneuverIcon[Constants.SOURCE]; //no icon by default
            distancetomaneuverValue.text="----";
            distancetodestinationValue.text="----";
            timetodestinationValue.text="----";
            roadaftermaneuverValue.text="----";
			return;
		} else { 
            guidanceStatus.setState("ON");
            Genivi.guidance_activated = true;
            //Guidance active, so inform the trip computer (refresh)
            Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,1,50);
		}

        var maneuversList=Genivi.guidance_GetManeuversList(dbusIf,1,0);
        var numberOfManeuvers=maneuversList[1];
        //only one maneuver is considered
        var maneuver=maneuversList[3][1];
        var roadNumberAfterManeuver=maneuver[1];
        var roadNameAfterManeuver=maneuver[3];
        var roadPropertyAfterManeuver=maneuver[5];
        var drivingSide=maneuver[7];
        var offsetOfNextManeuver=maneuver[9];
        var items=maneuver[11][1];
        var offsetOfManeuver=items[1];
        var travelTime=items[3];
        var direction=items[5];
        var maneuverType=items[7];
        var maneuverData=items[9];
        if (maneuverData[1] == Genivi.NAVIGATIONCORE_DIRECTION)
        {
            guidanceStatus.setState("ON");
            Genivi.guidance_activated = true;
            maneuverIcon.source=Genivi.ManeuverDirectionIcon[maneuverData[3][3][1]];
            //Genivi.ManeuverType[subarray[j+1][7]] contains CROSSROAD and is removed for the moment
            distancetomaneuverValue.text=Genivi.distance(offsetOfManeuver);
            roadaftermaneuverValue.text=roadNameAfterManeuver;
        }

        res=Genivi.guidance_GetDestinationInformation(dbusIf);
        distancetodestinationValue.text = Genivi.distance(res[1]);
        timetodestinationValue.text = Genivi.time(res[3]);

        updateAddress();
    }

	function stopGuidance()
	{
        Genivi.guidance_StopGuidance(dbusIf);
		updateGuidance();
	}

    function startGuidance()
    {
        Genivi.guidance_StartGuidance(dbusIf,Genivi.routing_handle(dbusIf));
        updateGuidance();
        updateSimulation();
        updateAddress();
    }

    function stopSimulation()
    {
        Genivi.mapmatchedposition_SetSimulationMode(dbusIf,0);
    }

    function startSimulation()
    {
        Genivi.mapmatchedposition_SetSimulationMode(dbusIf,1);
        Genivi.mapmatchedposition_StartSimulation(dbusIf);
    }

    Rectangle {
        id:map
        x:0
        y:0
        height:menu.height
        width:menu.width
        color:"transparent"

        Rectangle {
            color:"transparent"
            width: StyleSheetTop.navigation_browse_map_top_background[Constants.WIDTH]
            height: StyleSheetTop.navigation_browse_map_top_background[Constants.HEIGHT]
            x: StyleSheetMap.top_area[Constants.X]
            y: StyleSheetMap.top_area[Constants.Y]
            HMIBgImage {
                id: top
                opacity: 0.8
                image:StyleSheetTop.navigation_browse_map_top_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                SmartText {
                    x:StyleSheetTop.fsamessageText[Constants.X]; y:StyleSheetTop.fsamessageText[Constants.Y]; width:StyleSheetTop.fsamessageText[Constants.WIDTH]; height:StyleSheetTop.fsamessageText[Constants.HEIGHT];color:StyleSheetTop.fsamessageText[Constants.TEXTCOLOR];styleColor:StyleSheetTop.fsamessageText[Constants.STYLECOLOR]; font.pixelSize:StyleSheetTop.fsamessageText[Constants.PIXELSIZE];
                    id:fsamessageText
                    visible: true
                    text:""
                }

                StdButton {
                    source:StyleSheetTop.select_search_for_refill_in_top[Constants.SOURCE]; x:StyleSheetTop.select_search_for_refill_in_top[Constants.X]; y:StyleSheetTop.select_search_for_refill_in_top[Constants.Y]; width:StyleSheetTop.select_search_for_refill_in_top[Constants.WIDTH]; height:StyleSheetTop.select_search_for_refill_in_top[Constants.HEIGHT];
                    id:select_search_for_refill_in_top
                    visible:false
                    explode: false
                    onClicked: {
                        disconnectSignals();
                        entryMenu("POI",menu);
                                }
                        }

                SmartText {
                    x:StyleSheetTop.roadaftermaneuverValue[Constants.X]; y:StyleSheetTop.roadaftermaneuverValue[Constants.Y]; width:StyleSheetTop.roadaftermaneuverValue[Constants.WIDTH]; height:StyleSheetTop.roadaftermaneuverValue[Constants.HEIGHT];color:StyleSheetTop.roadaftermaneuverValue[Constants.TEXTCOLOR];styleColor:StyleSheetTop.roadaftermaneuverValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetTop.roadaftermaneuverValue[Constants.PIXELSIZE];
                    visible: true
                    id:roadaftermaneuverValue
                    text: " "
                }

                Text {
                    x:StyleSheetTop.speedValue[Constants.X]; y:StyleSheetTop.speedValue[Constants.Y]; width:StyleSheetTop.speedValue[Constants.WIDTH]; height:StyleSheetTop.speedValue[Constants.HEIGHT];color:StyleSheetTop.speedValue[Constants.TEXTCOLOR];styleColor:StyleSheetTop.speedValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetTop.speedValue[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:vehicleSpeedValue
                    text: "---"
                }

                Text {
                    x:StyleSheetTop.speedUnit[Constants.X]; y:StyleSheetTop.speedUnit[Constants.Y]; width:StyleSheetTop.speedUnit[Constants.WIDTH]; height:StyleSheetTop.speedUnit[Constants.HEIGHT];color:StyleSheetTop.speedUnit[Constants.TEXTCOLOR];styleColor:StyleSheetTop.speedUnit[Constants.STYLECOLOR]; font.pixelSize:StyleSheetTop.speedUnit[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:speedUnit
                    text: "km/h"
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetBottom.navigation_browse_map_bottom_background[Constants.WIDTH]
            height: StyleSheetBottom.navigation_browse_map_bottom_background[Constants.HEIGHT]
            x: StyleSheetMap.bottom_area[Constants.X]
            y: StyleSheetMap.bottom_area[Constants.Y]
            HMIBgImage {
                id: bottom
                opacity: 0.8
                image:StyleSheetBottom.navigation_browse_map_bottom_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                StdButton {
                    source:StyleSheetBottom.menub[Constants.SOURCE]; x:StyleSheetBottom.menub[Constants.X]; y:StyleSheetBottom.menub[Constants.Y]; width:StyleSheetBottom.menub[Constants.WIDTH]; height:StyleSheetBottom.menub[Constants.HEIGHT];textColor:StyleSheetBottom.menubText[Constants.TEXTCOLOR]; pixelSize:StyleSheetBottom.menubText[Constants.PIXELSIZE];
                    id:menub; text:Genivi.gettext("Menu"); next:orientation; prev:settings;
                    onClicked: {
                        disconnectSignals();
                        leaveMenu();;
                    }
                }

                StdButton {
                    x:StyleSheetBottom.directiondestination[Constants.X]; y:StyleSheetBottom.directiondestination[Constants.Y]; width:StyleSheetBottom.directiondestination[Constants.WIDTH]; height:StyleSheetBottom.directiondestination[Constants.HEIGHT];
                    id:orientation; next:zoomin; prev:menub; explode:false; disabled:false;
                    source:StyleSheetBottom.directiondestination[Constants.SOURCE]; //todo call get status
                    property int status: 0;
                    function setState(name)
                    {
                        if (name=="D")
                        {
                            status=1;
                            source=StyleSheetBottom.directionnorth[Constants.SOURCE];
                        }
                        else
                        {
                            status=0;
                            source=StyleSheetBottom.directiondestination[Constants.SOURCE];
                        }
                    }
                    onClicked:
                    {
                        toggleOrientation();
                    }
                }

                SmartText {
                    x:StyleSheetBottom.currentroad[Constants.X]; y:StyleSheetBottom.currentroad[Constants.Y]; width:StyleSheetBottom.currentroad[Constants.WIDTH]; height:StyleSheetBottom.currentroad[Constants.HEIGHT];color:StyleSheetBottom.currentroad[Constants.TEXTCOLOR];styleColor:StyleSheetBottom.currentroad[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBottom.currentroad[Constants.PIXELSIZE];
                    visible: true
                    id:currentroad
                    text: "-------"
                }

                StdButton {
                    source:StyleSheetBottom.zoomin[Constants.SOURCE]; x:StyleSheetBottom.zoomin[Constants.X]; y:StyleSheetBottom.zoomin[Constants.Y]; width:StyleSheetBottom.zoomin[Constants.WIDTH]; height:StyleSheetBottom.zoomin[Constants.HEIGHT];
                    id:zoomin; explode:false; next:zoomout; prev:orientation;
                    onClicked: {
                        Genivi.mapviewer_SetMapViewScaleByDelta(dbusIf,1);
                        showZoom();
                    }
                }

                Text {
                    x:StyleSheetBottom.zoomlevel[Constants.X]; y:StyleSheetBottom.zoomlevel[Constants.Y]; width:StyleSheetBottom.zoomlevel[Constants.WIDTH]; height:StyleSheetBottom.zoomlevel[Constants.HEIGHT];color:StyleSheetBottom.zoomlevel[Constants.TEXTCOLOR];styleColor:StyleSheetBottom.zoomlevel[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBottom.zoomlevel[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:zoomlevel
                    text: " "
                }

                StdButton {
                    source:StyleSheetBottom.zoomout[Constants.SOURCE]; x:StyleSheetBottom.zoomout[Constants.X]; y:StyleSheetBottom.zoomout[Constants.Y]; width:StyleSheetBottom.zoomout[Constants.WIDTH]; height:StyleSheetBottom.zoomout[Constants.HEIGHT];
                    id:zoomout; explode:false; next:settings; prev:zoomin;
                    onClicked: {
                        Genivi.mapviewer_SetMapViewScaleByDelta(dbusIf,-1);
                        showZoom();
                    }
                }

                StdButton {
                    source:StyleSheetBottom.settings[Constants.SOURCE]; x:StyleSheetBottom.settings[Constants.X]; y:StyleSheetBottom.settings[Constants.Y]; width:StyleSheetBottom.settings[Constants.WIDTH]; height:StyleSheetBottom.settings[Constants.HEIGHT];
                    id:settings; explode:false; next:menub; prev:zoomout;
                    onClicked: {
                        disconnectSignals();
                        entryMenu("CameraSettings",menu);
                    }
                }

                StdButton {
                    x:StyleSheetBottom.guidanceon[Constants.X]; y:StyleSheetBottom.guidanceon[Constants.Y]; width:StyleSheetBottom.guidanceon[Constants.WIDTH]; height:StyleSheetBottom.guidanceon[Constants.HEIGHT];
                    id:guidanceStatus; next:zoomin; prev:menub; explode:false; disabled:false;
                    source:StyleSheetBottom.guidanceoff[Constants.SOURCE]; //todo call get status
                    property int status: 1;
                    function setState(name)
                    {
                        if (name=="ON")
                        {
                            status=1;
                            source=StyleSheetBottom.guidanceoff[Constants.SOURCE];
                            guidance.visible=true;
                            route.visible=true;
                            simulation.visible=true;
                        }
                        else
                        {
                            status=0;
                            source=StyleSheetBottom.guidanceon[Constants.SOURCE];
                            guidance.visible=false;
                            route.visible=false;
                            simulation.visible=false;
                            if (Genivi.route_calculated == true)
                            {
                                visible=true; //it's possible to restart the current route
                            }
                            else {
                                visible=false; //no route calculated
                            }
                        }
                    }
                    onClicked:
                    {
                        if(status)
                        {
                            stopGuidance();
                            stopSimulation();
                        }
                        else {
                            startGuidance();
                        }
                    }
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetRoute.navigation_browse_map_route_background[Constants.WIDTH]
            height: StyleSheetRoute.navigation_browse_map_route_background[Constants.HEIGHT]
            x: StyleSheetMap.route_area[Constants.X]
            y: StyleSheetMap.route_area[Constants.Y]
            HMIBgImage {
                id: route
                opacity: 0.8
                image:StyleSheetRoute.navigation_browse_map_route_background[Constants.SOURCE]
                anchors { fill: parent; topMargin: parent.headlineHeight}
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        routeOverview();
                                }
                }

                Text {
                    x:StyleSheetRoute.timetodestinationValue[Constants.X]; y:StyleSheetRoute.timetodestinationValue[Constants.Y]; width:StyleSheetRoute.timetodestinationValue[Constants.WIDTH]; height:StyleSheetRoute.timetodestinationValue[Constants.HEIGHT];color:StyleSheetRoute.timetodestinationValue[Constants.TEXTCOLOR];styleColor:StyleSheetRoute.timetodestinationValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetRoute.timetodestinationValue[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:timetodestinationValue
                    text: "-------"
                }

                Text {
                    x:StyleSheetRoute.distancetodestinationValue[Constants.X]; y:StyleSheetRoute.distancetodestinationValue[Constants.Y]; width:StyleSheetRoute.distancetodestinationValue[Constants.WIDTH]; height:StyleSheetRoute.distancetodestinationValue[Constants.HEIGHT];color:StyleSheetRoute.distancetodestinationValue[Constants.TEXTCOLOR];styleColor:StyleSheetRoute.distancetodestinationValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetRoute.distancetodestinationValue[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:distancetodestinationValue
                    text: "----"
                }

            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetGuidance.navigation_browse_map_guidance_background[Constants.WIDTH]
            height: StyleSheetGuidance.navigation_browse_map_guidance_background[Constants.HEIGHT]
            x: StyleSheetMap.guidance_area[Constants.X]
            y: StyleSheetMap.guidance_area[Constants.Y]
            HMIBgImage {
                id: guidance
                opacity: 0.8
                image:StyleSheetGuidance.navigation_browse_map_guidance_background[Constants.SOURCE]
                anchors { fill: parent; topMargin: parent.headlineHeight}
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var res=Genivi.guidance_GetGuidanceStatus(dbusIf);
                        if (res[1] != Genivi.NAVIGATIONCORE_INACTIVE) {
                            disconnectSignals();
                            entryMenu("NavigationManeuversList",menu);
                        }
                    }
                }

                Text {
                    x:StyleSheetGuidance.distancetomaneuverValue[Constants.X]; y:StyleSheetGuidance.distancetomaneuverValue[Constants.Y]; width:StyleSheetGuidance.distancetomaneuverValue[Constants.WIDTH]; height:StyleSheetGuidance.distancetomaneuverValue[Constants.HEIGHT];color:StyleSheetGuidance.distancetomaneuverValue[Constants.TEXTCOLOR];styleColor:StyleSheetGuidance.distancetomaneuverValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetGuidance.distancetomaneuverValue[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:distancetomaneuverValue
                    text: " "
                }

                Text {
                    x:StyleSheetGuidance.maneuverAdvice[Constants.X]; y:StyleSheetGuidance.maneuverAdvice[Constants.Y]; width:StyleSheetGuidance.maneuverAdvice[Constants.WIDTH]; height:StyleSheetGuidance.maneuverAdvice[Constants.HEIGHT];color:StyleSheetGuidance.maneuverAdvice[Constants.TEXTCOLOR];styleColor:StyleSheetGuidance.maneuverAdvice[Constants.STYLECOLOR]; font.pixelSize:StyleSheetGuidance.maneuverAdvice[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:maneuverAdvice
                    text: " "
                }

                BorderImage {
                    id: maneuverIcon
                    source:StyleSheetGuidance.maneuverIcon[Constants.SOURCE]; x:StyleSheetGuidance.maneuverIcon[Constants.X]; y:StyleSheetGuidance.maneuverIcon[Constants.Y]; width:StyleSheetGuidance.maneuverIcon[Constants.WIDTH]; height:StyleSheetGuidance.maneuverIcon[Constants.HEIGHT];
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetScroll.navigation_browse_map_scroll_background[Constants.WIDTH]
            height: StyleSheetScroll.navigation_browse_map_scroll_background[Constants.HEIGHT]
            x: StyleSheetMap.scroll_area[Constants.X]
            y: StyleSheetMap.scroll_area[Constants.Y]
            HMIBgImage {
                opacity: 0.8
                property real panX: 40 //delta in pixel for x panning
                property real panY: 40 //delta in pixel for y panning
                id: scroll
                image:StyleSheetScroll.navigation_browse_map_scroll_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                StdButton {
                    source:StyleSheetScroll.scrollup[Constants.SOURCE]; x:StyleSheetScroll.scrollup[Constants.X]; y:StyleSheetScroll.scrollup[Constants.Y]; width:StyleSheetScroll.scrollup[Constants.WIDTH]; height:StyleSheetScroll.scrollup[Constants.HEIGHT];
                    id:scrollup; explode:false; next:scrollleft; prev:scrolldown;
                    onPressed: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["int32",Genivi.MAPVIEWER_PAN_START,"array",["structure",["uint16",map.width/2,"uint16",map.height/2]]]);}
                    onReleased: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["int32",Genivi.MAPVIEWER_PAN_END,"array",["structure",["uint16",map.width/2,"uint16",map.height/2 + scroll.panY]]]);}
                }

                StdButton {
                    source:StyleSheetScroll.scrollleft[Constants.SOURCE]; x:StyleSheetScroll.scrollleft[Constants.X]; y:StyleSheetScroll.scrollleft[Constants.Y]; width:StyleSheetScroll.scrollleft[Constants.WIDTH]; height:StyleSheetScroll.scrollleft[Constants.HEIGHT];
                    id:scrollleft; explode:false; next:scrollright; prev:scrollup;
                    onPressed: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["int32",Genivi.MAPVIEWER_PAN_START,"array",["structure",["uint16",map.width/2,"uint16",map.height/2]]]);}
                    onReleased: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["int32",Genivi.MAPVIEWER_PAN_END,"array",["structure",["uint16",map.width/2 + scroll.panX,"uint16",map.height/2]]]);}
                }

                StdButton {
                    source:StyleSheetScroll.scrollright[Constants.SOURCE]; x:StyleSheetScroll.scrollright[Constants.X]; y:StyleSheetScroll.scrollright[Constants.Y]; width:StyleSheetScroll.scrollright[Constants.WIDTH]; height:StyleSheetScroll.scrollright[Constants.HEIGHT];
                    id:scrollright; explode:false; next:scrolldown; prev:scrollleft;
                    onPressed: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["int32",Genivi.MAPVIEWER_PAN_START,"array",["structure",["uint16",map.width/2,"uint16",map.height/2]]]);}
                    onReleased: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["int32",Genivi.MAPVIEWER_PAN_END,"array",["structure",["uint16",map.width/2 - scroll.panX,"uint16",map.height/2]]]);}
                }

                StdButton {
                    source:StyleSheetScroll.scrolldown[Constants.SOURCE]; x:StyleSheetScroll.scrolldown[Constants.X]; y:StyleSheetScroll.scrolldown[Constants.Y]; width:StyleSheetScroll.scrolldown[Constants.WIDTH]; height:StyleSheetScroll.scrolldown[Constants.HEIGHT];
                    id:scrolldown; explode:false; next:scrollup; prev:scrollright;
                    onPressed: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["int32",Genivi.MAPVIEWER_PAN_START,"array",["structure",["uint16",map.width/2,"uint16",map.height/2]]]);}
                    onReleased: {Genivi.mapviewercontrol_message(dbusIf, "SetMapViewPan", ["int32",Genivi.MAPVIEWER_PAN_END,"array",["structure",["uint16",map.width/2,"uint16",map.height/2 - scroll.panY]]]);}
                }
            }
        }

        Rectangle {
            color:"transparent"

            width: StyleSheetSimulation.navigation_browse_map_simulation_background[Constants.WIDTH]
            height: StyleSheetSimulation.navigation_browse_map_simulation_background[Constants.HEIGHT]
            x: StyleSheetMap.simulation_area[Constants.X]
            y: StyleSheetMap.simulation_area[Constants.Y]
            HMIBgImage {
                id: simulation
                opacity: {
                    if (Genivi.simulationPanelOnMapview==true)
                    {
                        opacity=0.8;
                    }
                    else
                    {
                        opacity=0;
                    }
                }
                image:StyleSheetSimulation.navigation_browse_map_simulation_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}
                Text {
                    x:StyleSheetSimulation.speedValue_popup[Constants.X]; y:StyleSheetSimulation.speedValue_popup[Constants.Y]; width:StyleSheetSimulation.speedValue_popup[Constants.WIDTH]; height:StyleSheetSimulation.speedValue_popup[Constants.HEIGHT];color:StyleSheetSimulation.speedValue_popup[Constants.TEXTCOLOR];styleColor:StyleSheetSimulation.speedValue_popup[Constants.STYLECOLOR]; font.pixelSize:StyleSheetSimulation.speedValue_popup[Constants.PIXELSIZE];
                    id:speedValue
                    style: Text.Sunken;
                    smooth: true
                    text: ""
                     }
                StdButton {
                    source:StyleSheetSimulation.speed_down_popup[Constants.SOURCE]; x:StyleSheetSimulation.speed_down_popup[Constants.X]; y:StyleSheetSimulation.speed_down_popup[Constants.Y]; width:StyleSheetSimulation.speed_down_popup[Constants.WIDTH]; height:StyleSheetSimulation.speed_down_popup[Constants.HEIGHT];
                    id:speed_down; explode:false; disabled:false; next:speed_up; prev:simu_mode;
                    onClicked:
                    {
                        if (speedValueSent > 0)
                        {
                            speedValueSent = speedValueSent-1;
                        }
                        Genivi.mapmatchedposition_s(dbusIf,"SetSimulationSpeed",["uint8",getDBusSpeedValue(speedValueSent)]);
                    }
                }
                StdButton {
                    source:StyleSheetSimulation.speed_up_popup[Constants.SOURCE]; x:StyleSheetSimulation.speed_up_popup[Constants.X]; y:StyleSheetSimulation.speed_up_popup[Constants.Y]; width:StyleSheetSimulation.speed_up_popup[Constants.WIDTH]; height:StyleSheetSimulation.speed_up_popup[Constants.HEIGHT];
                    id:speed_up; explode:false; disabled:false; next:on_off; prev:speed_down;
                    onClicked:
                    {
                        if (speedValueSent < 7)
                        {
                            speedValueSent = speedValueSent+1;
                        }
                        Genivi.mapmatchedposition_s(dbusIf,"SetSimulationSpeed",["uint8",getDBusSpeedValue(speedValueSent)]);
                    }
                }
                StdButton {
                    x:StyleSheetSimulation.simulation_on_popup[Constants.X]; y:StyleSheetSimulation.simulation_on_popup[Constants.Y]; width:StyleSheetSimulation.simulation_on_popup[Constants.WIDTH]; height:StyleSheetSimulation.simulation_on_popup[Constants.HEIGHT];
                    id:on_off; next:simu_mode; prev:speed_up; explode:false; disabled:false;
                    property int status: 1; //by default simulation stopped
                    function setState(name)
                    {
                        if (name=="ON")
                        {
                            status=1;
                            source=StyleSheetSimulation.simulation_off_popup[Constants.SOURCE];
                        }
                        else
                        {
                            status=0;
                            source=StyleSheetSimulation.simulation_on_popup[Constants.SOURCE];
                        }
                    }
                    onClicked:
                    {
                        switch (status)
                        {
                            case 0: //start the simulation
                                startSimulation();
                            break;
                            case 1: //stop the simulation
                                stopSimulation();
                            break;
                            default:
                            break;
                        }
                    }
                }
                StdButton {
                    x:StyleSheetSimulation.play_popup[Constants.X]; y:StyleSheetSimulation.play_popup[Constants.Y]; width:StyleSheetSimulation.play_popup[Constants.WIDTH]; height:StyleSheetSimulation.play_popup[Constants.HEIGHT];
                    id:simu_mode; next:speed_down; prev:on_off; explode:false; disabled:false;
                    property int status: 0;
                    function setState(name)
                    {
                        if (name=="FREE")
                        {
                            status=0;
                            source=StyleSheetSimulation.play_popup[Constants.SOURCE];
                            disabled=true;
                        }
                        else
                        {
                            if (name=="PLAY")
                            {
                                status=1;
                                source=StyleSheetSimulation.pause_popup[Constants.SOURCE];
                                enabled=true;
                                disabled=false;
                            }
                            else
                            {
                                if (name=="PAUSE")
                                {
                                    status=2;
                                    source=StyleSheetSimulation.play_popup[Constants.SOURCE];
                                    enabled=true;
                                    disabled=false;
                                }
                            }
                        }
                    }
                    onClicked:
                    {
                        switch (status)
                        {
                            case 2: //pause
                                //pause to resume
                                Genivi.mapmatchedposition_s(dbusIf,"StartSimulation",[]);
                            break;
                            case 1: //play
                                //play to pause
                                Genivi.mapmatchedposition_s(dbusIf,"PauseSimulation",[]);
                            break;
                            default:
                            break;
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        Genivi.mapviewer_handle(dbusIf,menu.width,menu.height,Genivi.MAPVIEWER_MAIN_MAP);
		if (Genivi.data['show_route_handle']) {
            Genivi.mapviewer_DisplayRoute(dbusIf,Genivi.data['show_route_handle'],false);
			delete(Genivi.data['show_route_handle']);
		}
		if (Genivi.data['zoom_route_handle']) {
            var res=Genivi.navigationcore_message(dbusIf, "Routing", "GetRouteBoundingBox", Genivi.navigationcore_session(dbusIf).concat(Genivi.data['zoom_route_handle']));
			if (res[0] == "structure") {
				Genivi.mapviewercontrol_message(dbusIf, "SetMapViewBoundingBox", res);
			} else {
                console.log("Unexpected result from GetRouteBoundingBox:");
				Genivi.dump("",res);
			}
			delete(Genivi.data['zoom_route_handle']);
		}
		if (Genivi.data['show_position']) {
            Genivi.mapviewer_SetFollowCarMode(dbusIf,false);
            Genivi.mapviewer_SetTargetPoint(dbusIf,Genivi.data['show_position']['lat'],Genivi.data['show_position']['lon'],Genivi.data['show_position']['alt']);
			delete(Genivi.data['show_position']);
		}
		if (Genivi.data['show_current_position']) {
            Genivi.mapviewer_SetFollowCarMode(dbusIf,true);
			delete(Genivi.data['show_current_position']);
		}
		connectSignals();
		updateGuidance();
        updateSimulation();
        showZoom();
	}
}
