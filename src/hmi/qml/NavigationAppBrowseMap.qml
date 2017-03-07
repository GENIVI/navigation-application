/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2017, PSA GROUPE
*
* \file NavigationAppBrowseMap.qml
*
* \brief This file is part of the navigation hmi.
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
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
import QtQuick 2.1
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/NavigationAppBrowseMap-css.js" as StyleSheetMap;
import "Core/style-sheets/NavigationAppBrowseMapBottom-css.js" as StyleSheetBottom
import "Core/style-sheets/NavigationAppBrowseMapRoute-css.js" as StyleSheetRoute
import "Core/style-sheets/NavigationAppBrowseMapGuidance-css.js" as StyleSheetGuidance
import "Core/style-sheets/NavigationAppBrowseMapScroll-css.js" as StyleSheetScroll
import "Core/style-sheets/NavigationAppBrowseMapSimulation-css.js" as StyleSheetSimulation
import "Core/style-sheets/NavigationAppBrowseMapTop-css.js" as StyleSheetTop
import "Core/style-sheets/NavigationAppBrowseMapManeuver-css.js" as StyleSheetManeuver
import "Core/style-sheets/NavigationAppBrowseMapSettings-css.js" as StyleSheetSettings;

import lbs.plugin.dbusif 1.0

NavigationAppHMIMenu {
	id: menu
    property string pagefile:"NavigationAppBrowseMap"
    next: scrollup
	prev: menub
	property bool north:false;
    property int speedValueSent: 0;
    property bool displayManeuvers:false;

    //------------------------------------------//
    // Management of the DBus exchanges
    //------------------------------------------//
    DBusIf {
		id:dbusIf
	}

    property Item guidanceStatusChangedSignal;
    function guidanceStatusChanged(args)
    {
        Genivi.hookSignal("guidanceStatusChanged");
        if(args[1]===Genivi.NAVIGATIONCORE_ACTIVE)
        {
            showGuidance();
            showRoute();
            showSimulation();
            Genivi.guidance_activated = true;
            //Guidance active, so inform the trip computer (refresh)
            Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,1,50);
            updateGuidance();
        } else {
            hideGuidance();
            hideRoute();
            hideSimulation();
            if (Genivi.route_calculated == true)
            {
                visible=true; //it's possible to restart the current route
            }
            else {
                visible=false; //no route calculated
            }
            Genivi.guidance_activated = false;
            //Guidance inactive, so inform the trip computer
            Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,0,0);
            maneuverAdvice.text=Genivi.gettext("NoGuidance");
            maneuverIcon.source=StyleSheetGuidance.maneuverIcon[Constants.SOURCE]; //no icon by default
            distancetomaneuverValue.text="----";
            distancetodestinationValue.text="----";
            timetodestinationValue.text="----";
            roadaftermaneuverValue.text="----";
        }
    }

    property Item guidanceManeuverChangedSignal;
    function guidanceManeuverChanged(args)
    {
        Genivi.hookSignal("guidanceManeuverChanged");
        // TODO: Create possibility to poll information?
        // console.log("guidanceManeuverChanged");
        // Genivi.dump("",args);
        maneuverAdvice.text=Genivi.Maneuver[args[1]];
    }

    property Item guidanceWaypointReachedSignal;
    function guidanceWaypointReached(args)
    {
        Genivi.hookSignal("guidanceWaypointReached");
        // console.log("guidanceWaypointReached");
        // Genivi.dump("",args);
        if (args[2]) {
            maneuverAdvice.text="Destination reached";
        } else {
            maneuverAdvice.text="Waypoint reached";
        }

    }

    property Item guidancePositionOnRouteChangedSignal;
    function guidancePositionOnRouteChanged(args)
    {
        Genivi.hookSignal("guidancePositionOnRouteChanged");
        if(simu_mode.status!==0)
        { //for the time being it's necessary because of a bug in simulation use case
            updateGuidance();
        }
    }

    property Item mapmatchedpositionPositionUpdateSignal;
    function mapmatchedpositionPositionUpdate(args)
    {
        Genivi.hookSignal("mapmatchedpositionPositionUpdate");
        var res=Genivi.mapmatchedposition_GetPosition(dbusIf);
        for (var i=0;i<res[3].length;i+=4){
            if (res[3][i+1]== Genivi.NAVIGATIONCORE_SPEED){
                vehicleSpeedValue.text=res[3][i+3][3][1];
            } else {
                if ((res[3][i+1]== Genivi.NAVIGATIONCORE_LATITUDE) && (res[3][i+3][3][1] != 0)){
                    Genivi.data['current_position']['lat']=res[3][i+3][3][1];
                } else {
                    if ((res[3][i+1]== Genivi.NAVIGATIONCORE_LONGITUDE) && (res[3][i+3][3][1] != 0)){
                        Genivi.data['current_position']['lon']=res[3][i+3][3][1];
                    } else {
                        if (res[3][i+1]== Genivi.NAVIGATIONCORE_ALTITUDE){
                            Genivi.data['current_position']['alt']=res[3][i+3][3][1];
                        }
                    }
                }
            }
        }
    }

    property Item simulationSpeedChangedSignal;
    function simulationSpeedChanged(args)
    {
        Genivi.hookSignal("simulationSpeedChanged");
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

    property Item simulationStatusChangedSignal;
    function simulationStatusChanged(args)
    {
        Genivi.hookSignal("simulationStatusChanged");
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

    property Item mapmatchedpositionAddressUpdateSignal;
    function mapmatchedpositionAddressUpdate(args)
    {
        Genivi.hookSignal("mapmatchedpositionAddressUpdate");
        updateAddress();
    }

    property Item fuelStopAdvisorWarningSignal;
    function fuelStopAdvisorWarning(args)
    {
        Genivi.hookSignal("fuelStopAdvisorWarning");
        if (args[1] == 1)
        {
            fsamessageText.visible=true;
            fsamessageText.text=Genivi.gettext("FSAWarning");
            select_search_for_refill_in_top.visible=true;
            select_search_for_refill_in_top.disabled=false;
        }
        else
        {
            fsamessageText.visible=false;
            select_search_for_refill_in_top.visible=false;
            select_search_for_refill_in_top.disabled=true;
         }
    }

    property Item mapViewScaleChangedSignal;
    function mapViewScaleChanged(args)
    {
        Genivi.hookSignal("mapViewScaleChanged");
        var text=args[3].toString();
        if (args[5] === Genivi.MAPVIEWER_MAX) {
            text+="*";
        } else {
            if (args[5] === Genivi.MAPVIEWER_MIN)
                text="*"+text;
        }
        zoomlevel.text=text;
    }

    function connectSignals()
    {
        guidanceStatusChangedSignal=Genivi.connect_guidanceStatusChangedSignal(dbusIf,menu);
        guidanceWaypointReachedSignal=Genivi.connect_guidanceWaypointReachedSignal(dbusIf,menu);
        guidanceManeuverChangedSignal=Genivi.connect_guidanceManeuverChangedSignal(dbusIf,menu);
        guidancePositionOnRouteChangedSignal=Genivi.connect_guidancePositionOnRouteChangedSignal(dbusIf,menu);
        simulationStatusChangedSignal=Genivi.connect_simulationStatusChangedSignal(dbusIf,menu);
        simulationSpeedChangedSignal=Genivi.connect_simulationSpeedChangedSignal(dbusIf,menu);
        mapmatchedpositionPositionUpdateSignal=Genivi.connect_mapmatchedpositionPositionUpdateSignal(dbusIf,menu);
        mapmatchedpositionAddressUpdateSignal=Genivi.connect_mapmatchedpositionAddressUpdateSignal(dbusIf,menu);
        fuelStopAdvisorWarningSignal=Genivi.connect_fuelStopAdvisorWarningSignal(dbusIf,menu);
        mapViewScaleChangedSignal=Genivi.connect_mapViewScaleChangedSignal(dbusIf,menu)
    }

    function disconnectSignals()
    {
        guidanceStatusChangedSignal.destroy();
        guidanceWaypointReachedSignal.destroy();
        guidanceManeuverChangedSignal.destroy();
        guidancePositionOnRouteChangedSignal.destroy();
        simulationStatusChangedSignal.destroy();
        simulationSpeedChangedSignal.destroy();
        mapmatchedpositionPositionUpdateSignal.destroy();
        mapmatchedpositionAddressUpdateSignal.destroy();
        fuelStopAdvisorWarningSignal.destroy();
        mapViewScaleChangedSignal.destroy();
    }

    //------------------------------------------//
    // Time
    //------------------------------------------//
    Timer {
        id: time_in_top_timer
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: time_in_top.set()
    }

    //------------------------------------------//
    // Map settings
    //------------------------------------------//
    Timer {
        id:move_timer
        repeat:true
        triggeredOnStart:false
        property real lat;
        property real lon;
        property bool active;
        onTriggered: {
            if (active) {
                var res=Genivi.mapviewer_GetTargetPoint(dbusIf);
                var latitude=res[1][1]+lat;
                var longitude=res[1][3]+lon;
                var altitude=res[1][5];
                Genivi.mapviewer_SetTargetPoint(dbusIf,latitude,longitude,altitude);
                interval=50;
                restart();
            }
        }
    }

    Timer {
        id:camera_timer
        repeat:true
        triggeredOnStart:false
        property bool active;
        property string camera_value;
        property real step;
        property bool clamp;
        property real clamp_value;
        onTriggered: {
            if (active) {
                var res=Genivi.mapviewer_GetCameraValue(dbusIf,camera_value);
                res[1]+=step;
                if (clamp) {
                    if (step > 0 && res[1] > clamp_value) {
                        res[1]=clamp_value;
                    }
                    if (step < 0 && res[1] < clamp_value) {
                        res[1]=clamp_value;
                    }
                }
                Genivi.mapviewer_SetCameraValue(dbusIf,camera_value, res);
                interval=50;
                restart();
            }
        }
    }

    function move_start(lat, lon)
    {
        Genivi.mapviewer_SetFollowCarMode(dbusIf, false);
        move_timer.lat=lat/10000;
        move_timer.lon=lon/10000;
        move_timer.active=true;
        move_timer.triggered();
    }

    function move_stop()
    {
        move_timer.active=false;
        move_timer.stop();
    }

    function camera_start(camera_value, step)
    {
        camera_timer.camera_value=camera_value;
        camera_timer.step=step;
        camera_timer.active=true;
        camera_timer.triggered();
    }

    function camera_start_clamp(camera_value, step, clampvalue)
    {
        camera_timer.clamp=true;
        camera_timer.clamp_value=clampvalue;
        camera_start(camera_value, step);
    }

    function camera_stop()
    {
        camera_timer.active=false;
        camera_timer.stop();
        camera_timer.clamp=false;
    }

    function set_angle(angle)
    {
        Genivi.mapviewer_SetMapViewRotation(dbusIf,angle);
    }

    function updateMapViewer()
    {
        var res=Genivi.mapviewer_GetMapViewPerspective(dbusIf);
        if (res[1] == Genivi.MAPVIEWER_2D) {
            perspective.text=Genivi.gettext("CameraPerspective3d");
        } else {
            perspective.text=Genivi.gettext("CameraPerspective2d");
        }
        res=Genivi.mapviewer_GetDisplayedRoutes(dbusIf);
        if (res[1] && res[1].length) {
            split.disabled=false;
        } else {
            split.disabled=true;
        }
        if (Genivi.g_mapviewer_handle2) {
            split.text=Genivi.gettext("Join");
        } else {
            split.text=Genivi.gettext("Split");
        }
    }

    function toggleDayNight()
    {
        var res=Genivi.mapviewer_GetMapViewTheme(dbusIf);
        if (res[1] == Genivi.MAPVIEWER_THEME_1) {
            Genivi.mapviewer_SetMapViewTheme(dbusIf,Genivi.MAPVIEWER_THEME_2);
            if (Genivi.g_mapviewer_handle2) {
                Genivi.mapviewer2_SetMapViewTheme(dbusIf,Genivi.MAPVIEWER_THEME_2);
            }
            daynight.text=Genivi.gettext("Day");
        } else {
            Genivi.mapviewer_SetMapViewTheme(dbusIf,Genivi.MAPVIEWER_THEME_1);
            if (Genivi.g_mapviewer_handle2) {
                Genivi.mapviewer2_SetMapViewTheme(dbusIf,Genivi.MAPVIEWER_THEME_1);
            }
            daynight.text=Genivi.gettext("Night");
        }
    }

    function updateDayNight()
    {
        var res=Genivi.mapviewer_GetMapViewTheme(dbusIf);
        if (res[1] == Genivi.MAPVIEWER_THEME_1) {
            daynight.text=Genivi.gettext("Night");
        } else {
            daynight.text=Genivi.gettext("Day");
        }
    }

    function togglePerspective()
    {
        if (perspective.text == Genivi.gettext("CameraPerspective2d")) {
            Genivi.mapviewer_SetMapViewPerspective(dbusIf,Genivi.MAPVIEWER_2D);
        } else {
            Genivi.mapviewer_SetMapViewPerspective(dbusIf,Genivi.MAPVIEWER_3D);
        }
        updateMapViewer();
    }

    function toggleSplit() //split not tested yet
    {
        var displayedRoutes=Genivi.mapviewer_GetDisplayedRoutes(dbusIf);
        var mapViewTheme=Genivi.mapviewer_GetMapViewTheme(dbusIf);
        if (split.text == Genivi.gettext("Split")) {
            Genivi.mapviewer_handle_clear(dbusIf);
            Genivi.mapviewer_handle2(dbusIf,map.width/2,map.height,Genivi.MAPVIEWER_MAIN_MAP);
            Genivi.mapviewer_handle(dbusIf,map.width/2,map.height,Genivi.MAPVIEWER_MAIN_MAP);
            if (displayedRoutes[1] && displayedRoutes[1].length) {
                var boundingBox=Genivi.routing_GetRouteBoundingBox(dbusIf,[]);
                Genivi.mapviewer2_SetMapViewBoundingBox(dbusIf,boundingBox);
            }
            Genivi.mapviewer_SetMapViewTheme(dbusIf,mapViewTheme[1]);
            Genivi.mapviewer2_SetMapViewTheme(dbusIf,mapViewTheme[1]);
            Genivi.mapviewer_SetFollowCarMode(dbusIf,true);
        } else {
            Genivi.mapviewer_handle_clear2(dbusIf);
            Genivi.mapviewer_handle_clear(dbusIf);
            Genivi.mapviewer_handle(dbusIf,map.width,map.height,Genivi.MAPVIEWER_MAIN_MAP);
            Genivi.mapviewer_SetMapViewTheme(dbusIf,mapViewTheme[1]);
            Genivi.mapviewer_SetFollowCarMode(dbusIf,true);
        }
        if (displayedRoutes[1] && displayedRoutes[1].length) {
            var route=[];
            for (var i = 0 ; i < displayedRoutes[1].length ; i+=2) {
                route=displayedRoutes[1][i+1][0];
                route=route.concat(res[1][i+1][1]);
                Genivi.mapviewer_DisplayRoute(dbusIf,route,res[1][i+1][3]);
                if (split.text == Genivi.gettext("Split")) {
                    Genivi.mapviewer2_DisplayRoute(dbusIf,route,res[1][i+1][3]);
                }
            }
        }
        updateMapViewer();
    }

    function disableSplit() //split not tested yet
    {
        if (Genivi.g_mapviewer_handle2) {
            toggleSplit();
        }
    }

    function showMapSettings()
    {
        mapSettings.visible=true;
        tiltText.visible=true;
        tiltp.visible=true;
        tiltp.disabled=false;
        tiltm.visible=true;
        tiltm.disabled=false;
        heightText.visible=true;
        heightp.visible=true;
        heightp.disabled=false;
        heightm.visible=true;
        heightm.disabled=false;
        distanceText.visible=true;
        distancep.visible=true;
        distancep.disabled=false;
        distancem.visible=true;
        distancem.disabled=false;
        north.visible=true;
        north.disabled=false;
        south.visible=true;
        south.disabled=false;
        east.visible=true;
        east.disabled=false;
        west.visible=true;
        west.disabled=false;
        exitSettings.visible=true;
        exitSettings.disabled=false;
        split.visible=false; //split not tested yet
        split.disabled=true; //split not tested yet
        perspective.visible=true;
        perspective.disabled=false;
        daynight.visible=true;
        daynight.disabled=false;
    }

    function hideMapSettings()
    {
        mapSettings.visible=false;
        tiltText.visible=false;
        tiltp.visible=false;
        tiltp.disabled=true;
        tiltm.visible=false;
        tiltm.disabled=true;
        heightText.visible=false;
        heightp.visible=false;
        heightp.disabled=true;
        heightm.visible=false;
        heightm.disabled=true;
        distanceText.visible=false;
        distancep.visible=false;
        distancep.disabled=true;
        distancem.visible=false;
        distancem.disabled=true;
        north.visible=false;
        north.disabled=true;
        south.visible=false;
        south.disabled=true;
        east.visible=false;
        east.disabled=true;
        west.visible=false;
        west.disabled=true;
        exitSettings.visible=false;
        exitSettings.disabled=true;
        split.visible=false;
        split.disabled=true;
        perspective.visible=false;
        perspective.disabled=true;
        daynight.visible=false;
        daynight.disabled=true;
    }

    //------------------------------------------//
    // Map browsing
    //------------------------------------------//
    function updateSimulation()
    {
        var res=Genivi.mapmatchedposition_GetSimulationStatus(dbusIf);
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
        var res=Genivi.mapmatchedposition_GetCurrentAddress(dbusIf);
        if (res[3][1] == Genivi.NAVIGATIONCORE_STREET) {
            currentroad.text=res[3][3][3][1];
		} else {
            currentroad.text="";
		}
	}

	function showZoom()
	{
        var res=Genivi.mapviewer_GetMapViewScale(dbusIf);
        var text=res[1].toString();
        if (res[3] === Genivi.MAPVIEWER_MAX) {
            text+="*";
        } else {
            if (res[3] === Genivi.MAPVIEWER_MIN)
                text="*"+text;
        }
        zoomlevel.text=text;
	}

    function getManeuversList()
    {
        var res=Genivi.guidance_GetManeuversList(dbusIf,0xffff,0);
        var maneuversList=res[5];
        var model=maneuverArea.model;
        for (var i = 0 ; i < maneuversList.length ; i+=2) {
            var roadNameAfterManeuver=maneuversList[i+1][9];
            var offsetOfNextManeuver=maneuversList[i+1][15];
            var items=maneuversList[i+1][17];

            for (var j = 0 ; j < items.length ; j+=2) {
                //multiple maneuvers are not managed !
                var offsetOfManeuver=items[j+1][1];
                var direction=items[j+1][5];
                var maneuver=items[j+1][7];
                var maneuverData=items[j+1][9];
                if (maneuverData[1] == Genivi.NAVIGATIONCORE_DIRECTION)
                {
                   var text=Genivi.distance(offsetOfManeuver)+" "+Genivi.distance(offsetOfNextManeuver)+" "+Genivi.ManeuverType[maneuver]+":"+Genivi.ManeuverDirection[direction]+" "+roadNameAfterManeuver;
                   model.append({"name":text});
                }
            }
        }
    }

	function toggleOrientation()
	{
        if (!orientation.status) {
            Genivi.mapviewer_SetCameraHeadingAngle(dbusIf,0);
            orientation.setState("D");
		} else {
            Genivi.mapviewer_SetCameraHeadingTrackUp(dbusIf);
            orientation.setState("N");
		}
	}

	function updateGuidance()
	{
        var res=Genivi.guidance_GetManeuversList(dbusIf,1,0);
        //only one maneuver is considered
        //var error=res[1]
        var numberOfManeuvers=res[3];
        if(numberOfManeuvers > 0)
        {
            var maneuversList=res[5][1];
            //var roadShieldsAfterManeuver=maneuversList[1]
            //var countryCodeAfterManeuver=maneuversList[3]
            //var stateCodeAfterManeuver=maneuversList[5]
            var roadNumberAfterManeuver=maneuversList[7];
            var roadNameAfterManeuver=maneuversList[9];
            var roadPropertyAfterManeuver=maneuversList[11];
            var drivingSide=maneuversList[13];
            var offsetOfNextManeuver=maneuversList[15];
            var items=maneuversList[17][1];
            var offsetOfManeuver=items[1];
            var travelTime=items[3];
            var direction=items[5];
            var maneuverType=items[7];
            var maneuverData=items[9];
            if (maneuverData[1] == Genivi.NAVIGATIONCORE_DIRECTION)
            {
                maneuverIcon.source=Genivi.ManeuverDirectionIcon[maneuverData[3][3][1]];
                //Genivi.ManeuverType[subarray[j+1][7]] contains CROSSROAD and is removed for the moment
                distancetomaneuverValue.text=Genivi.distance(offsetOfManeuver);
                roadaftermaneuverValue.text=roadNameAfterManeuver;
            }
        } else {

        }

        var res1=Genivi.guidance_GetDestinationInformation(dbusIf);
        distancetodestinationValue.text = Genivi.distance(res1[1]);
        timetodestinationValue.text = Genivi.time(res1[3]);

        updateAddress();
    }

	function stopGuidance()
	{
        Genivi.guidance_StopGuidance(dbusIf);
	}

    function startGuidance()
    {
        Genivi.guidance_StartGuidance(dbusIf,Genivi.routing_handle(dbusIf));
        updateSimulation();
        updateAddress();
    }

    function stopSimulation()
    {
        Genivi.mapmatchedposition_PauseSimulation(dbusIf);
    }

    function startSimulation()
    {
        Genivi.mapmatchedposition_StartSimulation(dbusIf);
    }

    function showManeuversList()
    {
        displayManeuvers=true;
        maneuver.visible=true;
        route.visible=false;
        guidance.visible=false;
        maneuverList.disabled=true;
        exit.disabled=false;
        maneuverArea.model.clear();
        getManeuversList();
    }

    function hideManeuversList()
    {
        displayManeuvers=false;
        maneuver.visible=false;
        route.visible=true;
        guidance.visible=true;
        maneuverList.disabled=false;
        exit.disabled=true;
    }

    function showSimulation()
    {
        simulation.visible=true;
        speedValue.visible=true;
        speed_down.visible=true;
        speed_down.disabled=false;
        speed_up.visible=true;
        speed_up.disabled=false;
        simu_mode.visible=true;
        simu_mode.disabled=true;
        speedUnit.visible=true;
        vehicleSpeedValue.visible=true;
    }

    function hideSimulation()
    {
        simulation.visible=false;
        speedValue.visible=false;
        speed_down.visible=false;
        speed_down.disabled=true;
        speed_up.visible=false;
        speed_up.disabled=true;
        simu_mode.visible=false;
        simu_mode.disabled=true;
        speedUnit.visible=false;
        vehicleSpeedValue.visible=false;
    }

    function showGuidance()
    {
        guidance.visible=true;
    }

    function hideGuidance()
    {
        guidance.visible=false;
        fsamessageText.visible=false;
        select_search_for_refill_in_top.visible=false;
        select_search_for_refill_in_top.disabled=true;
    }

    function showRoute()
    {
        route.visible=true;
        maneuverList.disabled=false;
        roadaftermaneuverValue.visible=true;
    }

    function hideRoute()
    {
        route.visible=false;
        maneuverList.disabled=true;
        roadaftermaneuverValue.visible=false;
    }

    //------------------------------------------//
    // Menu elements
    //------------------------------------------//
    Rectangle {
        id:map
        x:0
        y:0
        height:menu.height
        width:menu.width
        color:"transparent"

        Rectangle {
            color:"transparent"
            width: StyleSheetTop.navigation_app_browse_map_top_background[Constants.WIDTH]
            height: StyleSheetTop.navigation_app_browse_map_top_background[Constants.HEIGHT]
            x: StyleSheetMap.top_area[Constants.X]
            y: StyleSheetMap.top_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: top
                opacity: 0.8
                image:StyleSheetTop.navigation_app_browse_map_top_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                Text {
                    x:StyleSheetTop.time_in_top[Constants.X]; y:StyleSheetTop.time_in_top[Constants.Y]; width:StyleSheetTop.time_in_top[Constants.WIDTH]; height:StyleSheetTop.time_in_top[Constants.HEIGHT];color:StyleSheetTop.time_in_top[Constants.TEXTCOLOR];styleColor:StyleSheetTop.time_in_top[Constants.STYLECOLOR]; font.pixelSize:StyleSheetTop.time_in_top[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:time_in_top
                    function set() {
                        text = Qt.formatTime(new Date(),"hh:mm")
                    }
                }

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
                    onClicked: {
                        disconnectSignals();
                        entryMenu("NavigationAppPOI",menu);
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
            width: StyleSheetBottom.navigation_app_browse_map_bottom_background[Constants.WIDTH]
            height: StyleSheetBottom.navigation_app_browse_map_bottom_background[Constants.HEIGHT]
            x: StyleSheetMap.bottom_area[Constants.X]
            y: StyleSheetMap.bottom_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: bottom
                opacity: 0.8
                image:StyleSheetBottom.navigation_app_browse_map_bottom_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                StdButton {
                    source:StyleSheetBottom.menub[Constants.SOURCE]; x:StyleSheetBottom.menub[Constants.X]; y:StyleSheetBottom.menub[Constants.Y]; width:StyleSheetBottom.menub[Constants.WIDTH]; height:StyleSheetBottom.menub[Constants.HEIGHT];textColor:StyleSheetBottom.menubText[Constants.TEXTCOLOR]; pixelSize:StyleSheetBottom.menubText[Constants.PIXELSIZE];
                    id:menub; text:Genivi.gettext("Back"); next:orientation; prev:settings;
                    onClicked: {
                        disconnectSignals();
                        Genivi.preloadMode=true;
                        leaveMenu();
                    }
                }

                StdButton {
                    x:StyleSheetBottom.directiondestination[Constants.X]; y:StyleSheetBottom.directiondestination[Constants.Y]; width:StyleSheetBottom.directiondestination[Constants.WIDTH]; height:StyleSheetBottom.directiondestination[Constants.HEIGHT];
                    id:orientation; next:zoomin; prev:menub;  disabled:false;
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
                    id:zoomin;  next:zoomout; prev:orientation;
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
                    id:zoomout;  next:settings; prev:zoomin;
                    onClicked: {
                        Genivi.mapviewer_SetMapViewScaleByDelta(dbusIf,-1);
                        showZoom();
                    }
                }

                StdButton {
                    source:StyleSheetBottom.mapsettings[Constants.SOURCE]; x:StyleSheetBottom.mapsettings[Constants.X]; y:StyleSheetBottom.mapsettings[Constants.Y]; width:StyleSheetBottom.mapsettings[Constants.WIDTH]; height:StyleSheetBottom.mapsettings[Constants.HEIGHT];
                    id:settings;  next:menub; prev:zoomout;
                    onClicked: {
                        if(mapSettings.visible===true) {
                            hideMapSettings();
                        } else {
                            showMapSettings();
                        }
                    }
                }

            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetRoute.navigation_app_browse_map_route_background[Constants.WIDTH]
            height: StyleSheetRoute.navigation_app_browse_map_route_background[Constants.HEIGHT]
            x: StyleSheetMap.route_area[Constants.X]
            y: StyleSheetMap.route_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: route
                opacity: 0.8
                image:StyleSheetRoute.navigation_app_browse_map_route_background[Constants.SOURCE]
                anchors { fill: parent; topMargin: parent.headlineHeight}
                StdButton {
                    source:StyleSheetRoute.show_maneuver_list[Constants.SOURCE]; x:StyleSheetRoute.show_maneuver_list[Constants.X]; y:StyleSheetRoute.show_maneuver_list[Constants.Y]; width:StyleSheetRoute.show_maneuver_list[Constants.WIDTH]; height:StyleSheetRoute.show_maneuver_list[Constants.HEIGHT];
                    id:maneuverList;
                    disabled:false;
                    onClicked: {
                        if(Genivi.guidance_activated)
                            showManeuversList();
                    }
                    next:maneuverList; prev:maneuverList;
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
            width: StyleSheetGuidance.navigation_app_browse_map_guidance_background[Constants.WIDTH]
            height: StyleSheetGuidance.navigation_app_browse_map_guidance_background[Constants.HEIGHT]
            x: StyleSheetMap.guidance_area[Constants.X]
            y: StyleSheetMap.guidance_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: guidance
                opacity: 0.8
                image:StyleSheetGuidance.navigation_app_browse_map_guidance_background[Constants.SOURCE]
                anchors { fill: parent; topMargin: parent.headlineHeight}
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if(Genivi.guidance_activated)
                            showManeuversList();
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
            width: StyleSheetScroll.navigation_app_browse_map_scroll_background[Constants.WIDTH]
            height: StyleSheetScroll.navigation_app_browse_map_scroll_background[Constants.HEIGHT]
            x: StyleSheetMap.scroll_area[Constants.X]
            y: StyleSheetMap.scroll_area[Constants.Y]
            NavigationAppHMIBgImage {
                opacity: 0.8
                property real panX: 40 //delta in pixel for x panning
                property real panY: 40 //delta in pixel for y panning
                id: scroll
                image:StyleSheetScroll.navigation_app_browse_map_scroll_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                StdButton {
                    source:StyleSheetScroll.scrollup[Constants.SOURCE]; x:StyleSheetScroll.scrollup[Constants.X]; y:StyleSheetScroll.scrollup[Constants.Y]; width:StyleSheetScroll.scrollup[Constants.WIDTH]; height:StyleSheetScroll.scrollup[Constants.HEIGHT];
                    id:scrollup;  next:scrollleft; prev:scrolldown;
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,Genivi.MAPVIEWER_PAN_END,map.width/2,map.height/2 + scroll.panY);}
                }

                StdButton {
                    source:StyleSheetScroll.scrollleft[Constants.SOURCE]; x:StyleSheetScroll.scrollleft[Constants.X]; y:StyleSheetScroll.scrollleft[Constants.Y]; width:StyleSheetScroll.scrollleft[Constants.WIDTH]; height:StyleSheetScroll.scrollleft[Constants.HEIGHT];
                    id:scrollleft;  next:scrollright; prev:scrollup;
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,Genivi.MAPVIEWER_PAN_END,map.width/2 + scroll.panX,map.height/2);}
                }

                StdButton {
                    source:StyleSheetScroll.scrollright[Constants.SOURCE]; x:StyleSheetScroll.scrollright[Constants.X]; y:StyleSheetScroll.scrollright[Constants.Y]; width:StyleSheetScroll.scrollright[Constants.WIDTH]; height:StyleSheetScroll.scrollright[Constants.HEIGHT];
                    id:scrollright;  next:scrolldown; prev:scrollleft;
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,Genivi.MAPVIEWER_PAN_END,map.width/2 - scroll.panX,map.height/2);}
                }

                StdButton {
                    source:StyleSheetScroll.scrolldown[Constants.SOURCE]; x:StyleSheetScroll.scrolldown[Constants.X]; y:StyleSheetScroll.scrolldown[Constants.Y]; width:StyleSheetScroll.scrolldown[Constants.WIDTH]; height:StyleSheetScroll.scrolldown[Constants.HEIGHT];
                    id:scrolldown;  next:scrollup; prev:scrollright;
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,Genivi.MAPVIEWER_PAN_END,map.width/2,map.height/2 - scroll.panY);}
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetSimulation.navigation_app_browse_map_simulation_background[Constants.WIDTH]
            height: StyleSheetSimulation.navigation_app_browse_map_simulation_background[Constants.HEIGHT]
            x: StyleSheetMap.simulation_area[Constants.X]
            y: StyleSheetMap.simulation_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: simulation
                opacity: 0.8
                image:StyleSheetSimulation.navigation_app_browse_map_simulation_background[Constants.SOURCE];
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
                    id:speed_down;  disabled:false; next:speed_up; prev:simu_mode;
                    onClicked:
                    {
                        if (speedValueSent > 0)
                        {
                            speedValueSent = speedValueSent-1;
                        }
                        Genivi.mapmatchedposition_SetSimulationSpeed(dbusIf,getDBusSpeedValue(speedValueSent));
                    }
                }
                StdButton {
                    source:StyleSheetSimulation.speed_up_popup[Constants.SOURCE]; x:StyleSheetSimulation.speed_up_popup[Constants.X]; y:StyleSheetSimulation.speed_up_popup[Constants.Y]; width:StyleSheetSimulation.speed_up_popup[Constants.WIDTH]; height:StyleSheetSimulation.speed_up_popup[Constants.HEIGHT];
                    id:speed_up;  disabled:false; next:simu_mode; prev:speed_down;
                    onClicked:
                    {
                        if (speedValueSent < 7)
                        {
                            speedValueSent = speedValueSent+1;
                        }
                        Genivi.mapmatchedposition_SetSimulationSpeed(dbusIf,getDBusSpeedValue(speedValueSent));
                    }
                }
                StdButton {
                    x:StyleSheetSimulation.play_popup[Constants.X]; y:StyleSheetSimulation.play_popup[Constants.Y]; width:StyleSheetSimulation.play_popup[Constants.WIDTH]; height:StyleSheetSimulation.play_popup[Constants.HEIGHT];
                    id:simu_mode; next:speed_down; prev:speed_up;  disabled:false;
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
                                Genivi.mapmatchedposition_StartSimulation(dbusIf);
                            break;
                            case 1: //play
                                //play to pause
                                Genivi.mapmatchedposition_PauseSimulation(dbusIf);
                            break;
                            default:
                            break;
                        }
                    }
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetManeuver.navigation_app_browse_map_maneuver_background[Constants.WIDTH]
            height: StyleSheetManeuver.navigation_app_browse_map_maneuver_background[Constants.HEIGHT]
            x: StyleSheetManeuver.maneuver_area[Constants.X]
            y: StyleSheetManeuver.maneuver_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: maneuver
                opacity: 0.8
                visible: (displayManeuvers)
                image:StyleSheetManeuver.navigation_app_browse_map_maneuver_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}
                StdButton {
                    source:StyleSheetManeuver.exit[Constants.SOURCE]; x:StyleSheetManeuver.exit[StyleSheetManeuver.X]; y:StyleSheetManeuver.exit[StyleSheetManeuver.Y]; width:StyleSheetManeuver.exit[StyleSheetManeuver.WIDTH]; height:StyleSheetManeuver.exit[StyleSheetManeuver.HEIGHT];
                    id:exit;  next:maneuverArea; prev:maneuverArea;
                    onClicked: { hideManeuversList(); }
                }
                Component {
                    id: maneuverDelegate
                    Text {
                        width:StyleSheetManeuver.maneuver_delegate[Constants.WIDTH]; height:StyleSheetManeuver.maneuver_delegate[Constants.HEIGHT];color:StyleSheetManeuver.maneuver_delegate[Constants.TEXTCOLOR];styleColor:StyleSheetManeuver.maneuver_delegate[Constants.STYLECOLOR]; font.pixelSize:StyleSheetManeuver.maneuver_delegate[Constants.PIXELSIZE];
                        id:maneuverItem;
                        text: name;
                        style: Text.Sunken;
                        smooth: true
                    }
                }
                NavigationAppHMIList {
                    property real selectedEntry
                    x:StyleSheetManeuver.maneuver_area[Constants.X]; y:StyleSheetManeuver.maneuver_area[Constants.Y]; width:StyleSheetManeuver.maneuver_area[Constants.WIDTH]; height:StyleSheetManeuver.maneuver_area[Constants.HEIGHT];
                    id:maneuverArea
                    delegate: maneuverDelegate
                    next:exit
                    prev:exit
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetSettings.navigation_app_browse_map_settings_background[Constants.WIDTH]
            height: StyleSheetSettings.navigation_app_browse_map_settings_background[Constants.HEIGHT]
            x: StyleSheetMap.settings_area[Constants.X]
            y: StyleSheetMap.settings_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: mapSettings
                opacity: 0.8
                image:StyleSheetSettings.navigation_app_browse_map_settings_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}
                 Text {
                     x:StyleSheetSettings.tiltText[StyleSheetSettings.X]; y:StyleSheetSettings.tiltText[StyleSheetSettings.Y]; width:StyleSheetSettings.tiltText[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.tiltText[StyleSheetSettings.HEIGHT];color:StyleSheetSettings.tiltText[StyleSheetSettings.TEXTCOLOR];styleColor:StyleSheetSettings.tiltText[StyleSheetSettings.STYLECOLOR]; font.pixelSize:StyleSheetSettings.tiltText[StyleSheetSettings.PIXELSIZE];
                     id:tiltText;
                     style: Text.Sunken;
                     smooth: true
                     text: Genivi.gettext("CameraTilt")
                      }
                 StdButton {
                     source:StyleSheetSettings.tiltp[Constants.SOURCE]; x:StyleSheetSettings.tiltp[StyleSheetSettings.X]; y:StyleSheetSettings.tiltp[StyleSheetSettings.Y]; width:StyleSheetSettings.tiltp[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.tiltp[StyleSheetSettings.HEIGHT];
                            id:tiltp;  next:tiltm; prev:daynight;
                         onPressed: {camera_start_clamp("CameraTiltAngle",-10,0);}
                         onReleased: {camera_stop();}
                 }
                 StdButton {
                     source:StyleSheetSettings.tiltm[Constants.SOURCE]; x:StyleSheetSettings.tiltm[StyleSheetSettings.X]; y:StyleSheetSettings.tiltm[StyleSheetSettings.Y]; width:StyleSheetSettings.tiltm[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.tiltm[StyleSheetSettings.HEIGHT];
                     id:tiltm;  next:heightp; prev:tiltp;
                     onPressed: {camera_start_clamp("CameraTiltAngle",10,90);}
                     onReleased: {camera_stop();}
                 }
                 Text {
                     x:StyleSheetSettings.heightText[StyleSheetSettings.X]; y:StyleSheetSettings.heightText[StyleSheetSettings.Y]; width:StyleSheetSettings.heightText[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.heightText[StyleSheetSettings.HEIGHT];color:StyleSheetSettings.heightText[StyleSheetSettings.TEXTCOLOR];styleColor:StyleSheetSettings.heightText[StyleSheetSettings.STYLECOLOR]; font.pixelSize:StyleSheetSettings.heightText[StyleSheetSettings.PIXELSIZE];
                     id:heightText;
                     style: Text.Sunken;
                     smooth: true
                     text: Genivi.gettext("CameraHeight")
                      }
                 StdButton {
                     source:StyleSheetSettings.heightp[Constants.SOURCE]; x:StyleSheetSettings.heightp[StyleSheetSettings.X]; y:StyleSheetSettings.heightp[StyleSheetSettings.Y]; width:StyleSheetSettings.heightp[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.heightp[StyleSheetSettings.HEIGHT];
                     id:heightp; next:heightm; prev:tiltm;
                     onPressed: {camera_start("CameraHeight",10);}
                     onReleased: {camera_stop();}
                 }
                 StdButton {
                     source:StyleSheetSettings.heightm[Constants.SOURCE]; x:StyleSheetSettings.heightm[StyleSheetSettings.X]; y:StyleSheetSettings.heightm[StyleSheetSettings.Y]; width:StyleSheetSettings.heightm[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.heightm[StyleSheetSettings.HEIGHT];
                     id:heightm;  next:distancep; prev:heightp;
                     onPressed: {camera_start("CameraHeight",-10);}
                     onReleased: {camera_stop();}
                 }
                 Text {
                     x:StyleSheetSettings.distanceText[StyleSheetSettings.X]; y:StyleSheetSettings.distanceText[StyleSheetSettings.Y]; width:StyleSheetSettings.distanceText[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.distanceText[StyleSheetSettings.HEIGHT];color:StyleSheetSettings.distanceText[StyleSheetSettings.TEXTCOLOR];styleColor:StyleSheetSettings.distanceText[StyleSheetSettings.STYLECOLOR]; font.pixelSize:StyleSheetSettings.distanceText[StyleSheetSettings.PIXELSIZE];
                     id:distanceText;
                     style: Text.Sunken;
                     smooth: true
                     text: Genivi.gettext("CameraDistance")
                      }
                 StdButton {
                     source:StyleSheetSettings.distancep[Constants.SOURCE]; x:StyleSheetSettings.distancep[StyleSheetSettings.X]; y:StyleSheetSettings.distancep[StyleSheetSettings.Y]; width:StyleSheetSettings.distancep[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.distancep[StyleSheetSettings.HEIGHT];
                     id:distancep;  next:distancem; prev:heightm;
                     onPressed: {camera_start("CameraDistanceFromTargetPoint",10);}
                     onReleased: {camera_stop();}
                 }
                 StdButton {
                     source:StyleSheetSettings.distancem[Constants.SOURCE]; x:StyleSheetSettings.distancem[StyleSheetSettings.X]; y:StyleSheetSettings.distancem[StyleSheetSettings.Y]; width:StyleSheetSettings.distancem[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.distancem[StyleSheetSettings.HEIGHT];
                            id:distancem;  next:exit; prev:distancep;
                         onPressed: {camera_start("CameraDistanceFromTargetPoint",-10);}
                         onReleased: {camera_stop();}
                 }
                 StdButton {
                     source:StyleSheetSettings.north[Constants.SOURCE]; x:StyleSheetSettings.north[StyleSheetSettings.X]; y:StyleSheetSettings.north[StyleSheetSettings.Y]; width:StyleSheetSettings.north[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.north[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.northText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.northText[StyleSheetSettings.PIXELSIZE];
                            id:north; text: Genivi.gettext("North");  next:south; prev:exit;
                     onClicked: {
                         set_angle(0);
                     }
                 }
                 StdButton {
                     source:StyleSheetSettings.south[Constants.SOURCE]; x:StyleSheetSettings.south[StyleSheetSettings.X]; y:StyleSheetSettings.south[StyleSheetSettings.Y]; width:StyleSheetSettings.south[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.south[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.southText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.southText[StyleSheetSettings.PIXELSIZE];
                            id:south; text:Genivi.gettext("South");  next:east; prev:north;
                     onClicked: {
                         set_angle(180);
                     }
                 }
                 StdButton {
                     source:StyleSheetSettings.east[Constants.SOURCE]; x:StyleSheetSettings.east[StyleSheetSettings.X]; y:StyleSheetSettings.east[StyleSheetSettings.Y]; width:StyleSheetSettings.east[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.east[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.eastText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.eastText[StyleSheetSettings.PIXELSIZE];
                            id:east; text:Genivi.gettext("East");  next:west; prev:south;
                     onClicked: {
                         set_angle(90);
                     }
                 }
                 StdButton {
                     source:StyleSheetSettings.west[Constants.SOURCE]; x:StyleSheetSettings.west[StyleSheetSettings.X]; y:StyleSheetSettings.west[StyleSheetSettings.Y]; width:StyleSheetSettings.west[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.west[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.westText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.westText[StyleSheetSettings.PIXELSIZE];
                            id:west; text:Genivi.gettext("West");  next:split; prev:east;
                     onClicked: {
                         set_angle(270);
                     }
                 }
                 StdButton {
                     source:StyleSheetSettings.exit[Constants.SOURCE]; x:StyleSheetSettings.exit[StyleSheetSettings.X]; y:StyleSheetSettings.exit[StyleSheetSettings.Y]; width:StyleSheetSettings.exit[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.exit[StyleSheetSettings.HEIGHT];
                            id:exitSettings;  next:north; prev:west;
                     onClicked: {
                         move_stop();
                         camera_stop();
                         hideMapSettings();
                     }
                 }
                 StdButton {
                     source:StyleSheetSettings.split[Constants.SOURCE]; x:StyleSheetSettings.split[StyleSheetSettings.X]; y:StyleSheetSettings.split[StyleSheetSettings.Y]; width:StyleSheetSettings.split[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.split[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.splitText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.splitText[StyleSheetSettings.PIXELSIZE];
                            id:split; text:Genivi.gettext("Split");  next:perspective; prev:west;
                         onClicked: {toggleSplit();} //split not tested yet
                 }
                 StdButton {
                     source:StyleSheetSettings.perspective[Constants.SOURCE]; x:StyleSheetSettings.perspective[StyleSheetSettings.X]; y:StyleSheetSettings.perspective[StyleSheetSettings.Y]; width:StyleSheetSettings.perspective[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.perspective[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.perspectiveText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.perspectiveText[StyleSheetSettings.PIXELSIZE];
                            id:perspective; text:Genivi.gettext("CameraPerspective3d");  next:daynight; prev:split;
                         onClicked: {togglePerspective();}
                 }
                 StdButton {
                     source:StyleSheetSettings.daynight[Constants.SOURCE]; x:StyleSheetSettings.daynight[StyleSheetSettings.X]; y:StyleSheetSettings.daynight[StyleSheetSettings.Y]; width:StyleSheetSettings.daynight[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.daynight[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.daynightText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.daynightText[StyleSheetSettings.PIXELSIZE];
                            id:daynight; text:Genivi.gettext("Day");  next:tiltp; prev:perspective;
                     onClicked: {
                         toggleDayNight();
                     }
                 }
             }
        }

    }

    Component.onCompleted: {
        connectSignals();
        hideMapSettings();

        if (Genivi.data['display_on_map']==='show_route') {
            //display the route when it has been calculated
            var res=Genivi.routing_GetRouteBoundingBox(dbusIf,Genivi.data['zoom_route_handle']);
            Genivi.mapviewer_SetMapViewBoundingBox(dbusIf,res);
            Genivi.mapviewer_DisplayRoute(dbusIf,Genivi.data['show_route_handle'],false);
            Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,1,50); //activate advisor mode
            hideGuidance();
            hideRoute();
            hideSimulation();
            updateAddress();
        }
        else {
            if (Genivi.data['display_on_map']==='show_current_position') {
                //show the current position
                Genivi.mapviewer_SetFollowCarMode(dbusIf,true);
                Genivi.mapviewer_SetMapViewScale(dbusIf,Genivi.zoom_guidance);
                if(Genivi.guidance_activated) {
                    if(Genivi.showroom) {
                        Genivi.data['current_position']=Genivi.data['default_position'];
                    }
                    Genivi.mapviewer_SetTargetPoint(dbusIf,Genivi.data['current_position']['lat'],Genivi.data['current_position']['lon'],Genivi.data['current_position']['alt']);
                    Genivi.mapviewer_DisplayRoute(dbusIf,Genivi.data['show_route_handle'],false);
                    Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,1,50); //activate advisor mode
                    showGuidance();
                    showRoute();
                    updateGuidance();
                    Genivi.mapmatchedposition_SetSimulationMode(dbusIf,Genivi.simulationMode);
                    if (Genivi.simulationMode===true)
                    {
                        showSimulation();
                        updateSimulation();
                    } else {
                        hideSimulation();
                    }
                } else {
                    if(Genivi.showroom) {
                        Genivi.data['current_position']=Genivi.data['default_position'];
                    }
                    Genivi.mapviewer_SetTargetPoint(dbusIf,Genivi.data['current_position']['lat'],Genivi.data['current_position']['lon'],Genivi.data['current_position']['alt']);
                    Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,0,50); //no advisor mode
                    hideGuidance();
                    hideRoute();
                    hideSimulation();
                    updateAddress();
                }
            }
            else {
                if (Genivi.data['display_on_map']==='show_position') {
                    //show a given position on the map, used to explore the map
                    Genivi.mapviewer_SetFollowCarMode(dbusIf,false);
                    Genivi.mapviewer_SetMapViewScale(dbusIf,Genivi.zoom_guidance);
                    Genivi.mapviewer_SetTargetPoint(dbusIf,Genivi.data['position']['lat'],Genivi.data['position']['lon'],Genivi.data['position']['alt']);
                    Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,0,50); //no advisor mode
                    hideGuidance();
                    hideRoute();
                    hideSimulation();
                    updateAddress();
                }
            }
        }
        showZoom();
	}
}
