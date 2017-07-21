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
import "../style-sheets/style-constants.js" as Constants;
import "../style-sheets/NavigationAppBrowseMap-css.js" as StyleSheetMap;
import "../style-sheets/NavigationAppBrowseMapBottom-css.js" as StyleSheetBottom
import "../style-sheets/NavigationAppBrowseMapRoute-css.js" as StyleSheetRoute
import "../style-sheets/NavigationAppBrowseMapGuidance-css.js" as StyleSheetGuidance
import "../style-sheets/NavigationAppBrowseMapScroll-css.js" as StyleSheetScroll
import "../style-sheets/NavigationAppBrowseMapSimulation-css.js" as StyleSheetSimulation
import "../style-sheets/NavigationAppBrowseMapTop-css.js" as StyleSheetTop
import "../style-sheets/NavigationAppBrowseMapManeuver-css.js" as StyleSheetManeuver
import "../style-sheets/NavigationAppBrowseMapScale-css.js" as StyleSheetScale;
import "../style-sheets/NavigationAppBrowseMapZoom-css.js" as StyleSheetZoom;
import "../style-sheets/NavigationAppBrowseMapCompass-css.js" as StyleSheetCompass;
import "../style-sheets/NavigationAppBrowseMapSettings-css.js" as StyleSheetSettings;


import lbs.plugin.dbusif 1.0
import lbs.plugin.dltif 1.0

NavigationAppHMIMenu {
	id: menu
    property string pagefile:"NavigationAppBrowseMap"
    next: scrollup
	prev: menub
    property int angle:0;
    property int speedValueSent: 0;
    property bool displayManeuvers:false; 
    property int currentZoomId;
    property string simulationSpeedRatio;

    DLTIf {
        id:dltIf;
        name: pagefile;
    }

    //------------------------------------------//
    // Management of the DBus exchanges
    //------------------------------------------//
    DBusIf {
		id:dbusIf
	}

    property Item guidanceStatusChangedSignal;
    function guidanceStatusChanged(args)
    {
        Genivi.hookSignal(dltIf,"guidanceStatusChanged");
        if(args[1]===Genivi.NAVIGATIONCORE_ACTIVE)
        {
            Genivi.setGuidanceActivated(dltIf,true);
            showGuidance();
            showRoute();
            if (Genivi.simulationMode===true)
            {
                Genivi.mapmatchedposition_SetSimulationMode(dbusIf,dltIf,Genivi.simulationMode);
                showSimulation();
                updateSimulation();
            } else {
                hideSimulation();
            }
            //Guidance active, so inform the trip computer (refresh)
            Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,1,50);
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
            Genivi.setGuidanceActivated(dltIf,false);
            //Guidance inactive, so inform the trip computer
            Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,0,0);
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
        Genivi.hookSignal(dltIf,"guidanceManeuverChanged");
        var advice = Genivi.Maneuver[args[1]];
        maneuverBarCru.visible=false;
        maneuverBarApp.visible=false;
        maneuverBarPre.visible=false;
        maneuverBarAdv.visible=false;
        if (advice=="CRU")
            maneuverBarCru.visible=true;
        else {
            if (advice=="APP")
                maneuverBarApp.visible=true;
            else {
                if (advice=="PRE")
                    maneuverBarPre.visible=true;
                else {
                    if (advice=="ADV")
                        maneuverBarAdv.visible=true;
                    }
            }
        }
    }

    property Item guidanceWaypointReachedSignal;
    function guidanceWaypointReached(args)
    {
        Genivi.hookSignal(dltIf,"guidanceWaypointReached");
        if (args[2]) {
            // "Destination reached" TBD
        } else {
            // "Waypoint reached" TBD
        }

    }

    property Item guidancePositionOnRouteChangedSignal;
    function guidancePositionOnRouteChanged(args)
    {
        Genivi.hookSignal(dltIf,"guidancePositionOnRouteChanged");
        if(simu_mode.status!==0)
        { //for the time being it's necessary because of a bug in simulation use case
            updateGuidance();
        }
    }

    property Item mapmatchedpositionPositionUpdateSignal;
    function mapmatchedpositionPositionUpdate(args)
    {
        Genivi.hookSignal(dltIf,"mapmatchedpositionPositionUpdate");
        var res=Genivi.mapmatchedposition_GetPosition(dbusIf,dltIf);
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
        Genivi.hookSignal(dltIf,"simulationSpeedChanged");
        if (args[1] == 0) {
            simulationSpeedRatio="0";
            speedValueSent=0;
        }
        if (args[1] == 1) {
            simulationSpeedRatio="1/4";
            speedValueSent=1;
        }
        if (args[1] == 2) {
            simulationSpeedRatio="1/2";
            speedValueSent=2;
        }
        if (args[1] == 4) {
            simulationSpeedRatio="1";
            speedValueSent=3;
        }
        if (args[1] == 8) {
            simulationSpeedRatio="2";
            speedValueSent=4;
        }
        if (args[1] == 16) {
            simulationSpeedRatio="4";
            speedValueSent=5;
        }
        if (args[1] == 32) {
            simulationSpeedRatio="8";
            speedValueSent=6;
        }
        if (args[1] == 64) {
            simulationSpeedRatio="16";
            speedValueSent=7;
        }
    }

    property Item simulationStatusChangedSignal;
    function simulationStatusChanged(args)
    {
        Genivi.hookSignal(dltIf,"simulationStatusChanged");
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
        Genivi.hookSignal(dltIf,"mapmatchedpositionAddressUpdate");
        updateAddress();
    }

    property Item fuelStopAdvisorWarningSignal;
    function fuelStopAdvisorWarning(args)
    {
        Genivi.hookSignal(dltIf,"fuelStopAdvisorWarning");
        if (args[1] == 1)
        {
            select_search_for_refill_in_top.visible=true;
            select_search_for_refill_in_top.disabled=false;
        }
        else
        {
            select_search_for_refill_in_top.visible=false;
            select_search_for_refill_in_top.disabled=true;
         }
    }

    property Item mapViewScaleChangedSignal;
    function mapViewScaleChanged(args)
    {
        Genivi.hookSignal(dltIf,"mapViewScaleChanged");
        var text=args[3].toString();
        currentZoomId=args[3];
        zoomin.disabled=false;
        zoomin.visible=true;
        zoomout.disabled=false;
        zoomout.visible=true;
        if(currentZoomId===Genivi.maxZoomId){
            zoomout.disabled=true;
            zoomout.visible=false;
            text+="*";
        }else{
            if(currentZoomId===Genivi.minZoomId){
                zoomin.disabled=true;
                zoomin.visible=false;
                text="*"+text;
            }
        }
        setScale(currentZoomId);
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
        id:rotation_timer
        repeat:true
        triggeredOnStart: false
        property bool clockwize;
        property int increment:10;
        property bool active;
        onTriggered: {
            if (active) {
                if(clockwize)
                {
                    if(angle>=350) angle=0; else angle+=increment;
                }else{
                    if(angle<=0) angle=350; else angle-=increment;
                }
                set_angle(angle);
                interval=50;
                restart();
                console.log(angle)
            }
        }
    }

    function rotation_start(clockwize)
    {
        rotation_timer.clockwize=clockwize;
        rotation_timer.active=true;
        rotation_timer.triggered();
    }

    function rotation_stop()
    {
        rotation_timer.active=false;
        rotation_timer.stop();
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
                var res=Genivi.mapviewer_GetCameraValue(dbusIf,dltIf,camera_value);
                res[1]+=step;
                if (clamp) {
                    if (step > 0 && res[1] > clamp_value) {
                        res[1]=clamp_value;
                    }
                    if (step < 0 && res[1] < clamp_value) {
                        res[1]=clamp_value;
                    }
                }
                Genivi.mapviewer_SetCameraValue(dbusIf,dltIf,camera_value, res);
                interval=50;
                restart();
            }
        }
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
        Genivi.mapviewer_SetMapViewRotation(dbusIf,dltIf,angle);
    }

    function showThreeDSettings()
    {
        threeDSettings.visible=true;
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
    }

    function hideThreeDSettings()
    {
        camera_stop();
        threeDSettings.visible=false;
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
    }

    //------------------------------------------//
    // Map browsing
    //------------------------------------------//
    function updateSimulation()
    {
        var res=Genivi.mapmatchedposition_GetSimulationStatus(dbusIf,dltIf);
        if (res[1] === Genivi.NAVIGATIONCORE_SIMULATION_STATUS_PAUSED || res[1] === Genivi.NAVIGATIONCORE_SIMULATION_STATUS_FIXED_POSITION)
        {
            simu_mode.setState("PAUSE");
        }
        else
        {
            if (res[1] === Genivi.NAVIGATIONCORE_SIMULATION_STATUS_RUNNING)
            {
                simu_mode.setState("PLAY");
            }
        }

        var res1=Genivi.mapmatchedposition_GetSimulationSpeed(dbusIf,dltIf);
        if (res1[1] === 0) {
            simulationSpeedRatio="0";
            speedValueSent=0;
        }
        if (res1[1] === 1) {
            simulationSpeedRatio="1/4";
            speedValueSent=1;
        }
        if (res1[1] === 2) {
            simulationSpeedRatio="1/2";
            speedValueSent=2;
        }
        if (res1[1] === 4) {
            simulationSpeedRatio="1";
            speedValueSent=3;
        }
        if (res1[1] === 8) {
            simulationSpeedRatio="2";
            speedValueSent=4;
        }
        if (res1[1] === 16) {
            simulationSpeedRatio="4";
            speedValueSent=5;
        }
        if (res1[1] === 32) {
            simulationSpeedRatio="8";
            speedValueSent=6;
        }
        if (res1[1] === 64) {
            simulationSpeedRatio="16";
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
        var res=Genivi.mapmatchedposition_GetCurrentAddress(dbusIf,dltIf);
        if (res[3][1] === Genivi.NAVIGATIONCORE_STREET) {
            currentroad.text=res[3][3][3][1];
		} else {
            currentroad.text="";
		}
	}

	function showZoom()
	{
        var res=Genivi.mapviewer_GetMapViewScale(dbusIf,dltIf);
        var text=res[1].toString();
        currentZoomId=res[1];
        zoomin.disabled=false;
        zoomin.visible=true;
        zoomout.disabled=false;
        zoomout.visible=true;
        if(currentZoomId===Genivi.maxZoomId){
            zoomout.disabled=true;
            zoomout.visible=false;
            text+="*";
        }else{
            if(currentZoomId===Genivi.minZoomId){
                zoomin.disabled=true;
                zoomin.visible=false;
                text="*"+text;
            }
        }
        setScale(currentZoomId);
    }

    function getManeuversList()
    {
        var res=Genivi.guidance_GetManeuversList(dbusIf,dltIf,0xffff,0);
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
    { //N->D->B
        if (orientation.status==0) {
            Genivi.mapviewer_SetCameraHeadingAngle(dbusIf,dltIf,0);
            Genivi.mapviewer_SetMapViewPerspective(dbusIf,dltIf,Genivi.MAPVIEWER_2D);
            orientation.setState("D");
		} else {
            if (orientation.status==1) {
                Genivi.mapviewer_SetCameraHeadingTrackUp(dbusIf,dltIf);
                Genivi.mapviewer_SetMapViewPerspective(dbusIf,dltIf,Genivi.MAPVIEWER_3D);
                orientation.setState("B");
                showThreeDSettings();
            } else{
                Genivi.mapviewer_SetMapViewPerspective(dbusIf,dltIf,Genivi.MAPVIEWER_2D);
                orientation.setState("N");
                hideThreeDSettings();
            }
		}
	}

    function toggleExploration()
    { //C->E
        if (exploration.status==0) {
            Genivi.mapviewer_SetFollowCarMode(dbusIf,dltIf, false);
            showScroll();
            exploration.setState("E");
        } else {
            if (exploration.status==1) {
                Genivi.mapviewer_SetFollowCarMode(dbusIf,dltIf, true);
                Genivi.mapviewer_SetMapViewScale(dbusIf,dltIf,Genivi.zoom_guidance);
                if (Genivi.data['display_on_map']==='show_current_position') {
                    Genivi.mapviewer_SetTargetPoint(dbusIf,dltIf,Genivi.data['current_position']['lat'],Genivi.data['current_position']['lon'],Genivi.data['current_position']['alt']);
                } else {
                    if (Genivi.data['display_on_map']==='show_position') {
                        Genivi.mapviewer_SetTargetPoint(dbusIf,dltIf,Genivi.data['position']['lat'],Genivi.data['position']['lon'],Genivi.data['position']['alt']);
                    }
                }
                hideScroll();
                exploration.setState("C");
            }
        }
    }

	function updateGuidance()
	{
        var res=Genivi.guidance_GetManeuversList(dbusIf,dltIf,1,0);
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

        var res1=Genivi.guidance_GetDestinationInformation(dbusIf,dltIf);
        distancetodestinationValue.text = Genivi.distance(res1[1]);
        timetodestinationValue.text = Genivi.time(res1[3]);

        updateAddress();
    }

	function stopGuidance()
	{
        Genivi.guidance_StopGuidance(dbusIf,dltIf);
	}

    function startGuidance()
    {
        Genivi.guidance_StartGuidance(dbusIf,dltIf,Genivi.routing_handle());
        updateSimulation();
        updateAddress();
    }

    function stopSimulation()
    {
        Genivi.mapmatchedposition_PauseSimulation(dbusIf,dltIf);
    }

    function startSimulation()
    {
        Genivi.mapmatchedposition_StartSimulation(dbusIf,dltIf);
    }

    function setScale(scaleId)
    {
        for(var index=0;index<Genivi.scaleList.length/2;index++)
        {
            if(scaleId===Genivi.scaleList[index*2+1][1])
            {
                var barLength;
                if(Genivi.scaleList[index*2+1][5]===Genivi.MAPVIEWER_METER){
                    barLength=(Genivi.scaleList[index*2+1][3]*1000)/Genivi.scaleList[index*2+1][7];
                    scale_bar.width=barLength;
                    right.x=left.x+left.width+scale_bar.width;
                    scaleValue.text=Genivi.scaleList[index*2+1][3]+" m";
                }else{
                    if(Genivi.scaleList[index*2+1][5]===Genivi.MAPVIEWER_KM){
                        barLength=(Genivi.scaleList[index*2+1][3]*1000000)/Genivi.scaleList[index*2+1][7];
                        scale_bar.width=barLength;
                        right.x=left.x+left.width+scale_bar.width;
                        scaleValue.text=Genivi.scaleList[index*2+1][3]+" km";
                    }
                }
                break;
            }

        }

        scale_bar.update();
        right.update();

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
        roadaftermaneuverBlock.visible=true;
    }

    function hideGuidance()
    {
        guidance.visible=false;
        roadaftermaneuverBlock.visible=false;
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

    function showScroll()
    {
        scroll.visible=true;
        scrollup.visible=true;
        scrollup.disabled=false;
        scrollleft.visible=true;
        scrollleft.disabled=false;
        scrollright.visible=true;
        scrollright.disabled=false;
        scrolldown.visible=true;
        scrolldown.disabled=false;
        rotateClockwize.visible=true;
        rotateClockwize.disabled=false;
        rotateAntiClockwize.visible=true;
        rotateAntiClockwize.disabled=false;
    }

    function hideScroll()
    {
        scroll.visible=false;
        scrollup.visible=false;
        scrollup.disabled=true;
        scrollleft.visible=false;
        scrollleft.disabled=true;
        scrollright.visible=false;
        scrollright.disabled=true;
        scrolldown.visible=false;
        scrolldown.disabled=true;
        rotateClockwize.visible=false;
        rotateClockwize.disabled=true;
        rotateAntiClockwize.visible=false;
        rotateAntiClockwize.disabled=true;
    }

    function showMapSettings()
    {
        mapSettings.visible=true;
        restartText.visible=true;
        restartGuidance.visible=true;
        restartGuidance.disabled=false;
        cancelText.visible=true;
        cancel.visible=true;
        cancel.disabled=false;
        exitSettings.visible=true;
        exitSettings.disabled=false;
        location_input.visible=true;
        location_input.disabled=false;
        poi.visible=true;
        poi.disabled=false;
    }

    function hideMapSettings()
    {
        mapSettings.visible=false;
        restartText.visible=false;
        restartGuidance.visible=false;
        restartGuidance.disabled=true;
        cancelText.visible=false;
        cancel.visible=false;
        cancel.disabled=true;
        exitSettings.visible=false;
        exitSettings.disabled=true;
        location_input.visible=false;
        location_input.disabled=true;
        poi.visible=false;
        poi.disabled=true;
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

                StdButton {
                    source:StyleSheetTop.select_search_for_refill_in_top[Constants.SOURCE]; x:StyleSheetTop.select_search_for_refill_in_top[Constants.X]; y:StyleSheetTop.select_search_for_refill_in_top[Constants.Y]; width:StyleSheetTop.select_search_for_refill_in_top[Constants.WIDTH]; height:StyleSheetTop.select_search_for_refill_in_top[Constants.HEIGHT];
                    id:select_search_for_refill_in_top
                    visible:false
                    onClicked: {
                        disconnectSignals();
                        entryMenu(dltIf,"NavigationAppPOI",menu);
                                }
                        }

                BorderImage {
                    id: roadaftermaneuverBlock
                    source:StyleSheetTop.roadaftermaneuverBlock[Constants.SOURCE]; x:StyleSheetTop.roadaftermaneuverBlock[Constants.X]; y:StyleSheetTop.roadaftermaneuverBlock[Constants.Y]; width:StyleSheetTop.roadaftermaneuverBlock[Constants.WIDTH]; height:StyleSheetTop.roadaftermaneuverBlock[Constants.HEIGHT];
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                    visible: false;
                }

                SmartText {
                    x:StyleSheetTop.roadaftermaneuverValue[Constants.X]; y:StyleSheetTop.roadaftermaneuverValue[Constants.Y]; width:StyleSheetTop.roadaftermaneuverValue[Constants.WIDTH]; height:StyleSheetTop.roadaftermaneuverValue[Constants.HEIGHT];color:StyleSheetTop.roadaftermaneuverValue[Constants.TEXTCOLOR];styleColor:StyleSheetTop.roadaftermaneuverValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetTop.roadaftermaneuverValue[Constants.PIXELSIZE];
                    visible: true
                    id:roadaftermaneuverValue
                    text: " "
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
                        if(Genivi.entrybackheapsize)
                            leaveMenu(dltIf);
                        else
                            pageOpen(dltIf,"NavigationAppMain");
                    }
                }

                SmartText {
                    x:StyleSheetBottom.currentroad[Constants.X]; y:StyleSheetBottom.currentroad[Constants.Y]; width:StyleSheetBottom.currentroad[Constants.WIDTH]; height:StyleSheetBottom.currentroad[Constants.HEIGHT];color:StyleSheetBottom.currentroad[Constants.TEXTCOLOR];styleColor:StyleSheetBottom.currentroad[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBottom.currentroad[Constants.PIXELSIZE];
                    visible: true
                    id:currentroad
                    text: "-------"
                }

                StdButton {
                    source:StyleSheetBottom.settings[Constants.SOURCE]; x:StyleSheetBottom.settings[Constants.X]; y:StyleSheetBottom.settings[Constants.Y]; width:StyleSheetBottom.settings[Constants.WIDTH]; height:StyleSheetBottom.settings[Constants.HEIGHT];
                    id:settings;
                    onClicked: {
                        disconnectSignals();
                        entryMenu(dltIf,"NavigationAppSettings",menu);
                    }
                }

                StdButton {
                    source:StyleSheetBottom.calculate_curr[Constants.SOURCE]; x:StyleSheetBottom.calculate_curr[Constants.X]; y:StyleSheetBottom.calculate_curr[Constants.Y]; width:StyleSheetBottom.calculate_curr[Constants.WIDTH]; height:StyleSheetBottom.calculate_curr[Constants.HEIGHT];
                    id:calculate_curr;
                    onClicked: {
                        if(Genivi.data['display_on_map']==='show_route')
                        {
                            // launch the guidance now !
                            Genivi.guidance_StartGuidance(dbusIf,dltIf,Genivi.routing_handle());

                        }else{
                            if(Genivi.data['display_on_map']==='show_position')
                            {
                              // launch a route calculation now !
                                disconnectSignals();
                                Genivi.data['destination']=Genivi.data['position'];
                                Genivi.setRerouteRequested(dltIf,true);
                                Genivi.guidance_StopGuidance(dbusIf,dltIf);
                                entryMenu(dltIf,"NavigationAppSearch",menu);
                            }
                            else{
                                if(mapSettings.visible===true)
                                    hideMapSettings();
                                else showMapSettings();
                            }
                        }
                    }
                }

                StdButton {
                    x:StyleSheetBottom.mapExploration[Constants.X]; y:StyleSheetBottom.mapExploration[Constants.Y]; width:StyleSheetBottom.mapExploration[Constants.WIDTH]; height:StyleSheetBottom.mapExploration[Constants.HEIGHT];
                    id:exploration; next:zoomin; prev:menub;  disabled:false;
                    source:StyleSheetBottom.gobackCurrent[Constants.SOURCE]; //todo call get status
                    property int status: 0;
                    function setState(name)
                    { //the icon displayed is the one of the current state
                        if (name=="E")
                        {
                            status=1;
                            source=StyleSheetBottom.mapExploration[Constants.SOURCE];
                        }
                        else
                        {
                            if (name=="C")
                            {
                                status=0;
                                source=StyleSheetBottom.gobackCurrent[Constants.SOURCE];
                            }
                        }
                    }
                    onClicked:
                    {
                        toggleExploration();
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

                BorderImage {
                    id: maneuverBarAdv
                    source:StyleSheetGuidance.maneuverBarAdv[Constants.SOURCE]; x:StyleSheetGuidance.maneuverBarAdv[Constants.X]; y:StyleSheetGuidance.maneuverBarAdv[Constants.Y]; width:StyleSheetGuidance.maneuverBarAdv[Constants.WIDTH]; height:StyleSheetGuidance.maneuverBarAdv[Constants.HEIGHT];
                    visible: false
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                }
                BorderImage {
                    id: maneuverBarPre
                    source:StyleSheetGuidance.maneuverBarPre[Constants.SOURCE]; x:StyleSheetGuidance.maneuverBarPre[Constants.X]; y:StyleSheetGuidance.maneuverBarPre[Constants.Y]; width:StyleSheetGuidance.maneuverBarPre[Constants.WIDTH]; height:StyleSheetGuidance.maneuverBarPre[Constants.HEIGHT];
                    visible: false
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                }
                BorderImage {
                    id: maneuverBarApp
                    source:StyleSheetGuidance.maneuverBarApp[Constants.SOURCE]; x:StyleSheetGuidance.maneuverBarApp[Constants.X]; y:StyleSheetGuidance.maneuverBarApp[Constants.Y]; width:StyleSheetGuidance.maneuverBarApp[Constants.WIDTH]; height:StyleSheetGuidance.maneuverBarApp[Constants.HEIGHT];
                    visible: false
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                }
                BorderImage {
                    id: maneuverBarCru
                    source:StyleSheetGuidance.maneuverBarCru[Constants.SOURCE]; x:StyleSheetGuidance.maneuverBarCru[Constants.X]; y:StyleSheetGuidance.maneuverBarCru[Constants.Y]; width:StyleSheetGuidance.maneuverBarCru[Constants.WIDTH]; height:StyleSheetGuidance.maneuverBarCru[Constants.HEIGHT];
                    visible: false
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
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
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_END,map.width/2,map.height/2 + scroll.panY);}
                }

                StdButton {
                    source:StyleSheetScroll.scrollleft[Constants.SOURCE]; x:StyleSheetScroll.scrollleft[Constants.X]; y:StyleSheetScroll.scrollleft[Constants.Y]; width:StyleSheetScroll.scrollleft[Constants.WIDTH]; height:StyleSheetScroll.scrollleft[Constants.HEIGHT];
                    id:scrollleft;  next:scrollright; prev:scrollup;
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_END,map.width/2 + scroll.panX,map.height/2);}
                }

                StdButton {
                    source:StyleSheetScroll.scrollright[Constants.SOURCE]; x:StyleSheetScroll.scrollright[Constants.X]; y:StyleSheetScroll.scrollright[Constants.Y]; width:StyleSheetScroll.scrollright[Constants.WIDTH]; height:StyleSheetScroll.scrollright[Constants.HEIGHT];
                    id:scrollright;  next:scrolldown; prev:scrollleft;
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_END,map.width/2 - scroll.panX,map.height/2);}
                }

                StdButton {
                    source:StyleSheetScroll.scrolldown[Constants.SOURCE]; x:StyleSheetScroll.scrolldown[Constants.X]; y:StyleSheetScroll.scrolldown[Constants.Y]; width:StyleSheetScroll.scrolldown[Constants.WIDTH]; height:StyleSheetScroll.scrolldown[Constants.HEIGHT];
                    id:scrolldown;  next:scrollup; prev:scrollright;
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_END,map.width/2,map.height/2 - scroll.panY);}
                }

                StdButton {
                    source:StyleSheetScroll.rotateClockwize[Constants.SOURCE]; x:StyleSheetScroll.rotateClockwize[Constants.X]; y:StyleSheetScroll.rotateClockwize[Constants.Y]; width:StyleSheetScroll.rotateClockwize[Constants.WIDTH]; height:StyleSheetScroll.rotateClockwize[Constants.HEIGHT];
                    id:rotateClockwize;
                    onPressed: {rotation_start(false);}
                    onReleased: {rotation_stop();}
                }

                StdButton {
                    source:StyleSheetScroll.rotateAntiClockwize[Constants.SOURCE]; x:StyleSheetScroll.rotateAntiClockwize[Constants.X]; y:StyleSheetScroll.rotateAntiClockwize[Constants.Y]; width:StyleSheetScroll.rotateAntiClockwize[Constants.WIDTH]; height:StyleSheetScroll.rotateAntiClockwize[Constants.HEIGHT];
                    id:rotateAntiClockwize;
                    onPressed: {rotation_start(true);}
                    onReleased: {rotation_stop();}
                }

                BorderImage {
                    id: threeDSettings
                    source:StyleSheetScroll.threeDSettings[Constants.SOURCE]; x:StyleSheetScroll.threeDSettings[Constants.X]; y:StyleSheetScroll.threeDSettings[Constants.Y]; width:StyleSheetScroll.threeDSettings[Constants.WIDTH]; height:StyleSheetScroll.threeDSettings[Constants.HEIGHT];
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                }

                Text {
                    x:StyleSheetScroll.tiltText[StyleSheetScroll.X]; y:StyleSheetScroll.tiltText[StyleSheetScroll.Y]; width:StyleSheetScroll.tiltText[StyleSheetScroll.WIDTH]; height:StyleSheetScroll.tiltText[StyleSheetScroll.HEIGHT];color:StyleSheetScroll.tiltText[StyleSheetScroll.TEXTCOLOR];styleColor:StyleSheetScroll.tiltText[StyleSheetScroll.STYLECOLOR]; font.pixelSize:StyleSheetScroll.tiltText[StyleSheetScroll.PIXELSIZE];
                    id:tiltText;
                    style: Text.Sunken;
                    smooth: true
                    text: Genivi.gettext("CameraTilt")
                     }
                StdButton {
                    source:StyleSheetScroll.tiltp[Constants.SOURCE]; x:StyleSheetScroll.tiltp[StyleSheetScroll.X]; y:StyleSheetScroll.tiltp[StyleSheetScroll.Y]; width:StyleSheetScroll.tiltp[StyleSheetScroll.WIDTH]; height:StyleSheetScroll.tiltp[StyleSheetScroll.HEIGHT];
                           id:tiltp;
                        onPressed: {camera_start_clamp("CameraTiltAngle",-10,0);}
                        onReleased: {camera_stop();}
                }
                StdButton {
                    source:StyleSheetScroll.tiltm[Constants.SOURCE]; x:StyleSheetScroll.tiltm[StyleSheetScroll.X]; y:StyleSheetScroll.tiltm[StyleSheetScroll.Y]; width:StyleSheetScroll.tiltm[StyleSheetScroll.WIDTH]; height:StyleSheetScroll.tiltm[StyleSheetScroll.HEIGHT];
                    id:tiltm;  next:heightp; prev:tiltp;
                    onPressed: {camera_start_clamp("CameraTiltAngle",10,90);}
                    onReleased: {camera_stop();}
                }

                Text {
                    x:StyleSheetScroll.heightText[StyleSheetScroll.X]; y:StyleSheetScroll.heightText[StyleSheetScroll.Y]; width:StyleSheetScroll.heightText[StyleSheetScroll.WIDTH]; height:StyleSheetScroll.heightText[StyleSheetScroll.HEIGHT];color:StyleSheetScroll.heightText[StyleSheetScroll.TEXTCOLOR];styleColor:StyleSheetScroll.heightText[StyleSheetScroll.STYLECOLOR]; font.pixelSize:StyleSheetScroll.heightText[StyleSheetScroll.PIXELSIZE];
                    id:heightText;
                    style: Text.Sunken;
                    smooth: true
                    text: Genivi.gettext("CameraHeight")
                     }
                StdButton {
                    source:StyleSheetScroll.heightp[Constants.SOURCE]; x:StyleSheetScroll.heightp[StyleSheetScroll.X]; y:StyleSheetScroll.heightp[StyleSheetScroll.Y]; width:StyleSheetScroll.heightp[StyleSheetScroll.WIDTH]; height:StyleSheetScroll.heightp[StyleSheetScroll.HEIGHT];
                    id:heightp; next:heightm; prev:tiltm;
                    onPressed: {camera_start("CameraHeight",10);}
                    onReleased: {camera_stop();}
                }
                StdButton {
                    source:StyleSheetScroll.heightm[Constants.SOURCE]; x:StyleSheetScroll.heightm[StyleSheetScroll.X]; y:StyleSheetScroll.heightm[StyleSheetScroll.Y]; width:StyleSheetScroll.heightm[StyleSheetScroll.WIDTH]; height:StyleSheetScroll.heightm[StyleSheetScroll.HEIGHT];
                    id:heightm;  next:distancep; prev:heightp;
                    onPressed: {camera_start("CameraHeight",-10);}
                    onReleased: {camera_stop();}
                }

                Text {
                    x:StyleSheetScroll.distanceText[StyleSheetScroll.X]; y:StyleSheetScroll.distanceText[StyleSheetScroll.Y]; width:StyleSheetScroll.distanceText[StyleSheetScroll.WIDTH]; height:StyleSheetScroll.distanceText[StyleSheetScroll.HEIGHT];color:StyleSheetScroll.distanceText[StyleSheetScroll.TEXTCOLOR];styleColor:StyleSheetScroll.distanceText[StyleSheetScroll.STYLECOLOR]; font.pixelSize:StyleSheetScroll.distanceText[StyleSheetScroll.PIXELSIZE];
                    id:distanceText;
                    style: Text.Sunken;
                    smooth: true
                    text: Genivi.gettext("CameraDistance")
                     }
                StdButton {
                    source:StyleSheetScroll.distancep[Constants.SOURCE]; x:StyleSheetScroll.distancep[StyleSheetScroll.X]; y:StyleSheetScroll.distancep[StyleSheetScroll.Y]; width:StyleSheetScroll.distancep[StyleSheetScroll.WIDTH]; height:StyleSheetScroll.distancep[StyleSheetScroll.HEIGHT];
                    id:distancep;  next:distancem; prev:heightm;
                    onPressed: {camera_start("CameraDistanceFromTargetPoint",10);}
                    onReleased: {camera_stop();}
                }
                StdButton {
                    source:StyleSheetScroll.distancem[Constants.SOURCE]; x:StyleSheetScroll.distancem[StyleSheetScroll.X]; y:StyleSheetScroll.distancem[StyleSheetScroll.Y]; width:StyleSheetScroll.distancem[StyleSheetScroll.WIDTH]; height:StyleSheetScroll.distancem[StyleSheetScroll.HEIGHT];
                           id:distancem;
                        onPressed: {camera_start("CameraDistanceFromTargetPoint",-10);}
                        onReleased: {camera_stop();}
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetZoom.navigation_app_browse_map_zoom_background[Constants.WIDTH]
            height: StyleSheetZoom.navigation_app_browse_map_zoom_background[Constants.HEIGHT]
            x: StyleSheetMap.zoom_area[Constants.X]
            y: StyleSheetMap.zoom_area[Constants.Y]
            NavigationAppHMIBgImage {
                opacity: 0.8
                id: zoom
                image:StyleSheetZoom.navigation_app_browse_map_zoom_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                StdButton {
                    source:StyleSheetZoom.zoomin[Constants.SOURCE]; x:StyleSheetZoom.zoomin[Constants.X]; y:StyleSheetZoom.zoomin[Constants.Y]; width:StyleSheetZoom.zoomin[Constants.WIDTH]; height:StyleSheetZoom.zoomin[Constants.HEIGHT];
                    id:zoomin;  next:zoomout; prev:orientation;
                    onClicked: {
                        if(currentZoomId>Genivi.minZoomId){
                            Genivi.mapviewer_SetMapViewScaleByDelta(dbusIf,dltIf,-1);
                        }
                    }
                }

                StdButton {
                    source:StyleSheetZoom.zoomout[Constants.SOURCE]; x:StyleSheetZoom.zoomout[Constants.X]; y:StyleSheetZoom.zoomout[Constants.Y]; width:StyleSheetZoom.zoomout[Constants.WIDTH]; height:StyleSheetZoom.zoomout[Constants.HEIGHT];
                    id:zoomout;  next:settings; prev:zoomin;
                    onClicked: {
                        if(currentZoomId<Genivi.maxZoomId){
                            Genivi.mapviewer_SetMapViewScaleByDelta(dbusIf,dltIf,1);
                        }
                    }
                }

            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetCompass.navigation_app_browse_map_compass_background[Constants.WIDTH]
            height: StyleSheetCompass.navigation_app_browse_map_compass_background[Constants.HEIGHT]
            x: StyleSheetMap.compass_area[Constants.X]
            y: StyleSheetMap.compass_area[Constants.Y]
            NavigationAppHMIBgImage {
                opacity: 0.8
                id: compass
                image:StyleSheetCompass.navigation_app_browse_map_compass_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                StdButton {
                    x:StyleSheetCompass.directiondestination[Constants.X]; y:StyleSheetCompass.directiondestination[Constants.Y]; width:StyleSheetCompass.directiondestination[Constants.WIDTH]; height:StyleSheetCompass.directiondestination[Constants.HEIGHT];
                    id:orientation; next:zoomin; prev:menub;  disabled:false;
                    source:StyleSheetCompass.directionnorth[Constants.SOURCE]; //todo call get status
                    property int status: 0;
                    function setState(name)
                    { //the icon displayed is the one of the current state
                        if (name=="N")
                        {
                            status=0;
                            source=StyleSheetCompass.directionnorth[Constants.SOURCE];
                        }
                        else
                        {
                            if (name=="D")
                            {
                                status=1;
                                source=StyleSheetCompass.directiondestination[Constants.SOURCE];
                            }
                            else
                            {
                                if (name=="B")
                                {
                                    status=2;
                                    source=StyleSheetCompass.directionThreeD[Constants.SOURCE];
                                }
                            }
                        }
                    }
                    onClicked:
                    {
                        toggleOrientation();
                    }
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
                    x:StyleSheetSimulation.speedValue[Constants.X]; y:StyleSheetSimulation.speedValue[Constants.Y]; width:StyleSheetSimulation.speedValue[Constants.WIDTH]; height:StyleSheetSimulation.speedValue[Constants.HEIGHT];color:StyleSheetSimulation.speedValue[Constants.TEXTCOLOR];styleColor:StyleSheetSimulation.speedValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetSimulation.speedValue[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:vehicleSpeedValue
                    text: "---"
                }

                Text {
                    x:StyleSheetSimulation.speedUnit[Constants.X]; y:StyleSheetSimulation.speedUnit[Constants.Y]; width:StyleSheetSimulation.speedUnit[Constants.WIDTH]; height:StyleSheetSimulation.speedUnit[Constants.HEIGHT];color:StyleSheetSimulation.speedUnit[Constants.TEXTCOLOR];styleColor:StyleSheetSimulation.speedUnit[Constants.STYLECOLOR]; font.pixelSize:StyleSheetSimulation.speedUnit[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:speedUnit
                    text: "km/h"
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
                        Genivi.mapmatchedposition_SetSimulationSpeed(dbusIf,dltIf,getDBusSpeedValue(speedValueSent));
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
                        Genivi.mapmatchedposition_SetSimulationSpeed(dbusIf,dltIf,getDBusSpeedValue(speedValueSent));
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
                                Genivi.mapmatchedposition_StartSimulation(dbusIf,dltIf);
                            break;
                            case 1: //play
                                //play to pause
                                Genivi.mapmatchedposition_PauseSimulation(dbusIf,dltIf);
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
            x: StyleSheetMap.maneuver_area[Constants.X]
            y: StyleSheetMap.maneuver_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: maneuver
                opacity: 0.8
                visible: (displayManeuvers)
                image:StyleSheetManeuver.navigation_app_browse_map_maneuver_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}
                StdButton {
                    source:StyleSheetManeuver.exit[Constants.SOURCE]; x:StyleSheetManeuver.exit[StyleSheetManeuver.X]; y:StyleSheetManeuver.exit[StyleSheetManeuver.Y]; width:StyleSheetManeuver.exit[StyleSheetManeuver.WIDTH]; height:StyleSheetManeuver.exit[StyleSheetManeuver.HEIGHT];
                    id:exit;
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
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetScale.navigation_app_browse_map_scale_background[Constants.WIDTH]
            height: StyleSheetScale.navigation_app_browse_map_scale_background[Constants.HEIGHT]
            x: StyleSheetMap.scale_area[Constants.X]
            y: StyleSheetMap.scale_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: scale
                opacity: 1
                image:StyleSheetScale.navigation_app_browse_map_scale_background[Constants.SOURCE]
                anchors { fill: parent; topMargin: parent.headlineHeight}
                Text {
                    x:StyleSheetScale.scaleValue[Constants.X]; y:StyleSheetScale.scaleValue[Constants.Y]; width:StyleSheetScale.scaleValue[Constants.WIDTH]; height:StyleSheetScale.scaleValue[Constants.HEIGHT];color:StyleSheetScale.scaleValue[Constants.TEXTCOLOR];styleColor:StyleSheetScale.scaleValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetScale.scaleValue[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:scaleValue
                    text: "-------"
                }
                BorderImage {
                    id: left
                    source: StyleSheetScale.left[Constants.SOURCE];x:StyleSheetScale.left[Constants.X]; y:StyleSheetScale.left[Constants.Y]; width:StyleSheetScale.left[Constants.WIDTH]; height:StyleSheetScale.left[Constants.HEIGHT];
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                    visible: true;
                }
                BorderImage {
                    id: scale_bar
                    source: StyleSheetScale.scale_bar[Constants.SOURCE];x:StyleSheetScale.scale_bar[Constants.X]; y:StyleSheetScale.scale_bar[Constants.Y]; width:StyleSheetScale.scale_bar[Constants.WIDTH]; height:StyleSheetScale.scale_bar[Constants.HEIGHT];
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                    visible: true;
                }
                BorderImage {
                    id: right
                    source: StyleSheetScale.right[Constants.SOURCE];x:StyleSheetScale.right[Constants.X]; y:StyleSheetScale.right[Constants.Y]; width:StyleSheetScale.right[Constants.WIDTH]; height:StyleSheetScale.right[Constants.HEIGHT];
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                    visible: true;
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
                     x:StyleSheetSettings.restartText[StyleSheetSettings.X]; y:StyleSheetSettings.restartText[StyleSheetSettings.Y]; width:StyleSheetSettings.restartText[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.restartText[StyleSheetSettings.HEIGHT];color:StyleSheetSettings.restartText[StyleSheetSettings.TEXTCOLOR];styleColor:StyleSheetSettings.restartText[StyleSheetSettings.STYLECOLOR]; font.pixelSize:StyleSheetSettings.restartText[StyleSheetSettings.PIXELSIZE];
                     id:restartText;
                     style: Text.Sunken;
                     smooth: true
                     text: Genivi.gettext("Restart")
                      }
                 StdButton {
                     source:StyleSheetSettings.restart[Constants.SOURCE]; x:StyleSheetSettings.restart[StyleSheetSettings.X]; y:StyleSheetSettings.restart[StyleSheetSettings.Y]; width:StyleSheetSettings.restart[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.restart[StyleSheetSettings.HEIGHT];
                     id:restartGuidance;
                     disabled: (Genivi.guidance_activated || !Genivi.route_calculated)
                     onPressed: {
                         //restart guidance
                         Genivi.guidance_StartGuidance(dbusIf,dltIf,Genivi.routing_handle());
                     }
                 }
                 Text {
                     x:StyleSheetSettings.cancelText[StyleSheetSettings.X]; y:StyleSheetSettings.cancelText[StyleSheetSettings.Y]; width:StyleSheetSettings.cancelText[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.cancelText[StyleSheetSettings.HEIGHT];color:StyleSheetSettings.cancelText[StyleSheetSettings.TEXTCOLOR];styleColor:StyleSheetSettings.cancelText[StyleSheetSettings.STYLECOLOR]; font.pixelSize:StyleSheetSettings.cancelText[StyleSheetSettings.PIXELSIZE];
                     id:cancelText;
                     style: Text.Sunken;
                     smooth: true
                     text: Genivi.gettext("Cancel")
                      }
                 StdButton {
                     source:StyleSheetSettings.cancel[Constants.SOURCE]; x:StyleSheetSettings.cancel[StyleSheetSettings.X]; y:StyleSheetSettings.cancel[StyleSheetSettings.Y]; width:StyleSheetSettings.cancel[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.cancel[StyleSheetSettings.HEIGHT];
                     id:cancel;
                     disabled: !(Genivi.guidance_activated);
                     onPressed: {
                        //stop guidance
                         Genivi.guidance_StopGuidance(dbusIf,dltIf);
                     }
                 }
                 StdButton {
                     source:StyleSheetSettings.location_input[Constants.SOURCE]; x:StyleSheetSettings.location_input[StyleSheetSettings.X]; y:StyleSheetSettings.location_input[StyleSheetSettings.Y]; width:StyleSheetSettings.location_input[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.location_input[StyleSheetSettings.HEIGHT];
                     id:location_input;
                     onPressed: {
                         disconnectSignals();
                         Genivi.setLocationInputActivated(dltIf,true);
                         entryMenu(dltIf,"NavigationAppSearch",menu);
                     }
                 }
                 StdButton {
                     source:StyleSheetSettings.poi[Constants.SOURCE]; x:StyleSheetSettings.poi[StyleSheetSettings.X]; y:StyleSheetSettings.poi[StyleSheetSettings.Y]; width:StyleSheetSettings.poi[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.poi[StyleSheetSettings.HEIGHT];
                     id:poi;
                     onPressed: {
                         disconnectSignals();
                         Genivi.setLocationInputActivated(dltIf,false);
                         entryMenu(dltIf,"NavigationAppPOI",menu);
                     }
                 }
                 StdButton {
                     source:StyleSheetSettings.exit[Constants.SOURCE]; x:StyleSheetSettings.exit[StyleSheetSettings.X]; y:StyleSheetSettings.exit[StyleSheetSettings.Y]; width:StyleSheetSettings.exit[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.exit[StyleSheetSettings.HEIGHT];
                     id:exitSettings;
                     onPressed: {
                        hideMapSettings();
                     }
                 }
            }
        }
    }

    Component.onCompleted: {
        connectSignals();

        if (Genivi.data['display_on_map']==='show_route') {
            //display the route when it has been calculated
            var res=Genivi.routing_GetRouteBoundingBox(dbusIf,dltIf,Genivi.data['zoom_route_handle']);
            Genivi.mapviewer_SetMapViewBoundingBox(dbusIf,dltIf,res);
            Genivi.mapviewer_DisplayRoute(dbusIf,dltIf,Genivi.data['show_route_handle'],false);
            Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,1,50); //activate advisor mode
            hideGuidance();
            hideRoute();
            hideSimulation();
            updateAddress();
        }
        else {
            if (Genivi.data['display_on_map']==='show_current_position') {
                //show the current position
                Genivi.mapviewer_SetFollowCarMode(dbusIf,dltIf,true);
                Genivi.mapviewer_SetMapViewScale(dbusIf,dltIf,Genivi.zoom_guidance);
                if(Genivi.guidance_activated) {
                    if(Genivi.showroom) {
                        Genivi.data['current_position']=Genivi.data['default_position'];
                    }
                    Genivi.mapviewer_SetTargetPoint(dbusIf,dltIf,Genivi.data['current_position']['lat'],Genivi.data['current_position']['lon'],Genivi.data['current_position']['alt']);
                    Genivi.mapviewer_DisplayRoute(dbusIf,dltIf,Genivi.data['show_route_handle'],false);
                    Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,1,50); //activate advisor mode
                    showGuidance();
                    showRoute();
                    updateGuidance();
                    if (Genivi.simulationMode===true)
                    {
                        Genivi.mapmatchedposition_SetSimulationMode(dbusIf,dltIf,Genivi.simulationMode);
                        showSimulation();
                        updateSimulation();
                    } else {
                        hideSimulation();
                    }
                } else {
                    if(Genivi.showroom) {
                        Genivi.data['current_position']=Genivi.data['default_position'];
                    }
                    Genivi.mapviewer_SetTargetPoint(dbusIf,dltIf,Genivi.data['current_position']['lat'],Genivi.data['current_position']['lon'],Genivi.data['current_position']['alt']);
                    Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,0,50); //no advisor mode
                    hideGuidance();
                    hideRoute();
                    hideSimulation();
                    updateAddress(); //there's a pb of accuracy of SetPosition in mapmatchedposition
                }
            }
            else {
                if (Genivi.data['display_on_map']==='show_position') {
                    //show a given position on the map, used to explore the map
                    Genivi.mapviewer_SetFollowCarMode(dbusIf,dltIf,false);
                    Genivi.mapviewer_SetMapViewScale(dbusIf,dltIf,Genivi.zoom_guidance);
                    Genivi.mapviewer_SetTargetPoint(dbusIf,dltIf,Genivi.data['position']['lat'],Genivi.data['position']['lon'],Genivi.data['position']['alt']);
                    Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,0,50); //no advisor mode
                    hideGuidance();
                    hideRoute();
                    hideSimulation();
                    updateAddress(); //there's a pb of accuracy of SetPosition in mapmatchedposition
                }
            }
        }

        hideMapSettings();
        hideScroll();
        hideThreeDSettings();
        exploration.setState("C");
        showZoom();
	}
}
