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
import "../style-sheets/NavigationAppBrowseMap-css.js" as StyleSheetBrowseMap;
import "../style-sheets/NavigationAppBrowseMapBottom-css.js" as StyleSheetBrowseMapBottom
import "../style-sheets/NavigationAppBrowseMapRoute-css.js" as StyleSheetBrowseMapRoute
import "../style-sheets/NavigationAppBrowseMapGuidance-css.js" as StyleSheetBrowseMapGuidance
import "../style-sheets/NavigationAppBrowseMapScroll-css.js" as StyleSheetBrowseMapScroll
import "../style-sheets/NavigationAppBrowseMapSimulation-css.js" as StyleSheetBrowseMapSimulation
import "../style-sheets/NavigationAppBrowseMapTop-css.js" as StyleSheetBrowseMapTop
import "../style-sheets/NavigationAppBrowseMapManeuver-css.js" as StyleSheetBrowseMapManeuver
import "../style-sheets/NavigationAppBrowseMapScale-css.js" as StyleSheetBrowseMapScale;
import "../style-sheets/NavigationAppBrowseMapZoom-css.js" as StyleSheetBrowseMapZoom;
import "../style-sheets/NavigationAppBrowseMapCompass-css.js" as StyleSheetBrowseMapCompass;
import "../style-sheets/NavigationAppBrowseMapSettings-css.js" as StyleSheetBrowseMapSettings;


import lbs.plugin.dbusif 1.0
import lbs.plugin.dltif 1.0

NavigationAppHMIMenu {
	id: menu
    property string pagefile:"NavigationAppBrowseMap"
    property int angle:0;
    property int speedValueSent: 0;
    property bool displayManeuvers:false; 
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

    property Item routeCalculationSuccessfulSignal;
    function routeCalculationSuccessful(args)
    { //routeHandle 1, unfullfilledPreferences 3
        Genivi.hookSignal(dltIf,"routeCalculationSuccessful");

        statusValue.visible=false;

        Genivi.setRouteCalculated(dltIf,true);

        // Give the route handle to the FSA
        Genivi.fuelstopadvisor_SetRouteHandle(dbusIf,dltIf,Genivi.g_routing_handle);

        // launch the guidance now !
        startGuidance();
    }

    property Item routeCalculationFailedSignal;
    function routeCalculationFailed(args)
    {
        Genivi.hookSignal(dltIf,"routeCalculationFailed");
        statusValue.visible=true;
        statusValue.text=Genivi.gettext("CalculatedRouteFailed");
        Genivi.setRouteCalculated(dltIf,false);
        // Tell the FSA that there's no route available
        Genivi.fuelstopadvisor_ReleaseRouteHandle(dbusIf,dltIf,Genivi.g_routing_handle);
    }

    property Item routeCalculationProgressUpdateSignal;
    function routeCalculationProgressUpdate(args)
    {
        Genivi.hookSignal(dltIf,"routeCalculationProgressUpdate");
        statusValue.visible=true;
        statusValue.text=Genivi.gettext("CalculatedRouteInProgress");
        Genivi.setRouteCalculated(dltIf,false);
    }

    property Item guidanceStatusChangedSignal;
    function guidanceStatusChanged(args)
    {
        Genivi.hookSignal(dltIf,"guidanceStatusChanged");
        if(args[1]===Genivi.NAVIGATIONCORE_ACTIVE)
        {
            Genivi.setGuidanceActivated(dltIf,true);
            Genivi.data['display_on_map']='show_current_position';
            Genivi.data['show_route_handle']=Genivi.routing_handle();
            Genivi.data['zoom_route_handle']=Genivi.routing_handle();
            rootMenu(dltIf,pagefile); //reload the whole menu to init the guidance
        } else {
            Genivi.setGuidanceActivated(dltIf,false);
            //keep the mapviewersettings panel open to choose what to do after
            hideGuidancePanel();
            hideRoutePanel();
            hideSimulationPanel();
            cancel.disabled=true;
            restartGuidance.disabled=false;
            //Guidance inactive, so inform the trip computer
            Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,0,0);
        }
    }

    property Item guidanceManeuverChangedSignal;
    function guidanceManeuverChanged(args)
    {
        Genivi.hookSignal(dltIf,"guidanceManeuverChanged");
        var advice = Genivi.Maneuver[args[1]];
        console.log(advice)
        maneuverBarCru.visible=false;
        maneuverBarApp.visible=false;
        maneuverBarPre.visible=false;
        maneuverBarAdv.visible=false;
        if (advice==="CRU" || advice==="PAS")
            maneuverBarCru.visible=true;
        else {
            if (advice==="APP")
                maneuverBarApp.visible=true;
            else {
                if (advice==="PRE")
                    maneuverBarPre.visible=true;
                else {
                    if (advice==="ADV")
                        maneuverBarAdv.visible=true;
                    }
            }
        }
    }

    property Item guidanceWaypointReachedSignal;
    function guidanceWaypointReached(args)
    {
        Genivi.hookSignal(dltIf,"guidanceWaypointReached");
        if (args[1]) {
            // "Destination reached"
            exitRoute();
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

    property Item mapmatchedpositionAddressUpdateSignal;
    function mapmatchedpositionAddressUpdate(args)
    {
        Genivi.hookSignal(dltIf,"mapmatchedpositionAddressUpdate");
        updateAddress();
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
        Genivi.currentZoomId=args[3];
        zoomin.disabled=false;
        zoomin.visible=true;
        zoomout.disabled=false;
        zoomout.visible=true;
        if(Genivi.currentZoomId===Genivi.maxZoomId){
            zoomout.disabled=true;
            zoomout.visible=false;
            text+="*";
        }else{
            if(Genivi.currentZoomId===Genivi.minZoomId){
                zoomin.disabled=true;
                zoomin.visible=false;
                text="*"+text;
            }
        }
        setScale(Genivi.currentZoomId);
    }

    property Item mapViewPerspectiveChangedSignal;
    function mapViewPerspectiveChanged(args)
    {
        Genivi.hookSignal(dltIf,"mapViewPerspectiveChanged");
        var perspective=args[3];
        if(perspective===Genivi.MAPVIEWER_3D){
            orientation.setState("B");
            showThreeDSettingsPanel();
        }else{
            hideThreeDSettingsPanel();
            if (orientation.status==0)
                orientation.setState("D")
            else{
                if (orientation.status==2)
                    orientation.setState("N");
            }
        }
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
        routeCalculationSuccessfulSignal=Genivi.connect_routeCalculationSuccessfulSignal(dbusIf,menu);
        routeCalculationFailedSignal=Genivi.connect_routeCalculationFailedSignal(dbusIf,menu);
        routeCalculationProgressUpdateSignal=Genivi.connect_routeCalculationProgressUpdateSignal(dbusIf,menu);
        fuelStopAdvisorWarningSignal=Genivi.connect_fuelStopAdvisorWarningSignal(dbusIf,menu);
        mapViewScaleChangedSignal=Genivi.connect_mapViewScaleChangedSignal(dbusIf,menu)
        mapViewPerspectiveChangedSignal=Genivi.connect_mapViewPerspectiveChangedSignal(dbusIf,menu)
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
        routeCalculationSuccessfulSignal.destroy();
        routeCalculationFailedSignal.destroy();
        routeCalculationProgressUpdateSignal.destroy();
        fuelStopAdvisorWarningSignal.destroy();
        mapViewScaleChangedSignal.destroy();
        mapViewPerspectiveChangedSignal.destroy();
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
                    if(angle>=360) angle=increment; else angle+=increment;
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

    function showThreeDSettingsPanel()
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

    function hideThreeDSettingsPanel()
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
        var text=Genivi.currentZoomId.toString();
        zoomin.disabled=false;
        zoomin.visible=true;
        zoomout.disabled=false;
        zoomout.visible=true;
        if(Genivi.currentZoomId===Genivi.maxZoomId){
            zoomout.disabled=true;
            zoomout.visible=false;
            text+="*";
        }else{
            if(Genivi.currentZoomId===Genivi.minZoomId){
                zoomin.disabled=true;
                zoomin.visible=false;
                text="*"+text;
            }
        }
        setScale(Genivi.currentZoomId);
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
                if (maneuverData[1] === Genivi.NAVIGATIONCORE_DIRECTION)
                {
                    var text=Genivi.distance(offsetOfManeuver)+" "+Genivi.ManeuverDirection[maneuverData[3][3][1]]+" "+roadNameAfterManeuver;
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
		} else {
            if (orientation.status==1) {
                Genivi.mapviewer_SetCameraHeadingTrackUp(dbusIf,dltIf);
                Genivi.mapviewer_SetMapViewPerspective(dbusIf,dltIf,Genivi.MAPVIEWER_3D);
            } else{
                Genivi.mapviewer_SetMapViewPerspective(dbusIf,dltIf,Genivi.MAPVIEWER_2D);
            }
		}
	}

    function toggleExploration()
    { //C->E
        if (exploration.status==0) {
            Genivi.mapviewer_SetFollowCarMode(dbusIf,dltIf, false);
            Genivi.mapmatchedposition_PauseSimulation(dbusIf,dltIf);
            showScrollPanel();
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
                hideScrollPanel();
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
        var timetodestination = res1[3]; //in sec
        //following stuff can be improved, it's a first attempt :-)
        var dateTime = new Date();
        timeofarrivalValue.text=Genivi.time(parseInt(Qt.formatTime(dateTime,"hh"),10)*3600+parseInt(Qt.formatTime(dateTime,"mm"),10)*60+parseInt(Qt.formatTime(dateTime,"ss"),10)+timetodestination,false);

        updateAddress();
    }

    function startGuidance()
    {
        Genivi.guidance_StartGuidance(dbusIf,dltIf,Genivi.routing_handle());
        maneuverIcon.source=StyleSheetBrowseMapGuidance.maneuverIcon[Constants.SOURCE]; //no icon by default
        updateSimulation();
        updateAddress();
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

    function launchRouteCalculation()
    {
        var position,destination;

        //launch route calculation
        destination=Genivi.latlon_to_map(Genivi.data['destination']);
        if(Genivi.showroom) {
            position=Genivi.latlon_to_map(Genivi.data['default_position']);
            Genivi.routing_SetWaypoints(dbusIf,dltIf,false,position,destination); //start from given position
        }else{
            position=Genivi.latlon_to_map(Genivi.data['current_position']);
            Genivi.routing_SetWaypoints(dbusIf,dltIf,true,position,destination); //start from current position
        }

        Genivi.routing_CalculateRoute(dbusIf,dltIf);
    }

    function exitRoute()
    {
        //if needed, reset the guidance and the routing to enter a new destination
        if(Genivi.guidance_activated)
        {
            Genivi.setGuidanceActivated(dltIf,false);
            Genivi.guidance_StopGuidance(dbusIf,dltIf);
            //Guidance inactive, so inform the trip computer
            Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,0,0);
        }
        if(Genivi.route_calculated)
        {
            Genivi.routing_DeleteRoute(dbusIf,dltIf,Genivi.g_routing_handle);
            Genivi.setRouteCalculated(dltIf,false);
        }
    }

    function showManeuversListPanel()
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

    function hideManeuversListPanel()
    {
        displayManeuvers=false;
        maneuver.visible=false;
        route.visible=true;
        guidance.visible=true;
        maneuverList.disabled=false;
        exit.disabled=true;
    }

    function showSimulationPanel()
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

    function hideSimulationPanel()
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

    function showGuidancePanel()
    {
        guidance.visible=true;
        distancetomaneuverValue.visible=true;
        roadaftermaneuverValue.visible=true;
        maneuverIcon.visible=true;
    }

    function hideGuidancePanel()
    {
        guidance.visible=false;
        distancetomaneuverValue.visible=false;
        roadaftermaneuverValue.visible=false;
        maneuverIcon.visible=false;
        select_search_for_refill_in_top.visible=false;
        select_search_for_refill_in_top.disabled=true;
    }

    function showRoutePanel()
    {
        route.visible=true;
        maneuverList.disabled=false;
        distancetodestinationValue.visible=true;
        timeofarrivalValue.visible=true;
    }

    function hideRoutePanel()
    {
        route.visible=false;
        maneuverList.disabled=true;
        distancetodestinationValue.visible=false;
        timeofarrivalValue.visible=false;
    }

    function showScrollPanel()
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

    function hideScrollPanel()
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

    function showMapSettingsPanel()
    {
        mapSettings.visible=true;
        restartGuidance.visible=true;
        restartGuidance.disabled=(Genivi.guidance_activated || !Genivi.route_calculated);
        cancel.visible=true;
        cancel.disabled=!(Genivi.guidance_activated);
        exitSettings.visible=true;
        exitSettings.disabled=false;
        location_input.visible=true;
        location_input.disabled=false;
        poi.visible=true;
        poi.disabled=false;
    }

    function hideMapSettingsPanel()
    {
        mapSettings.visible=false;
        restartGuidance.visible=false;
        restartGuidance.disabled=true;
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
            width: StyleSheetBrowseMapTop.navigation_app_browse_map_top_background[Constants.WIDTH]
            height: StyleSheetBrowseMapTop.navigation_app_browse_map_top_background[Constants.HEIGHT]
            x: StyleSheetBrowseMap.top_area[Constants.X]
            y: StyleSheetBrowseMap.top_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: top
                opacity: 0.8
                image:StyleSheetBrowseMapTop.navigation_app_browse_map_top_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                Text {
                    x:StyleSheetBrowseMapTop.time_in_top[Constants.X]; y:StyleSheetBrowseMapTop.time_in_top[Constants.Y]; width:StyleSheetBrowseMapTop.time_in_top[Constants.WIDTH]; height:StyleSheetBrowseMapTop.time_in_top[Constants.HEIGHT];color:StyleSheetBrowseMapTop.time_in_top[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapTop.time_in_top[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapTop.time_in_top[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:time_in_top
                    function set() {
                        text = Qt.formatTime(new Date(),"hh:mm")
                    }
                }

                StdButton {
                    source:StyleSheetBrowseMapTop.select_search_for_refill_in_top[Constants.SOURCE]; x:StyleSheetBrowseMapTop.select_search_for_refill_in_top[Constants.X]; y:StyleSheetBrowseMapTop.select_search_for_refill_in_top[Constants.Y]; width:StyleSheetBrowseMapTop.select_search_for_refill_in_top[Constants.WIDTH]; height:StyleSheetBrowseMapTop.select_search_for_refill_in_top[Constants.HEIGHT];
                    id:select_search_for_refill_in_top
                    visible:false
                    onClicked: {
                        disconnectSignals();
                        entryMenu(dltIf,"NavigationAppPOI",menu);
                    }
                }

                SmartText {
                    x:StyleSheetBrowseMapTop.statusValue[Constants.X]; y:StyleSheetBrowseMapTop.statusValue[Constants.Y]; width:StyleSheetBrowseMapTop.statusValue[Constants.WIDTH]; height:StyleSheetBrowseMapTop.statusValue[Constants.HEIGHT];color:StyleSheetBrowseMapTop.statusValue[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapTop.statusValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapTop.statusValue[Constants.PIXELSIZE];
                    id:statusValue
                    text: ""
                    visible: false;
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetBrowseMapBottom.navigation_app_browse_map_bottom_background[Constants.WIDTH]
            height: StyleSheetBrowseMapBottom.navigation_app_browse_map_bottom_background[Constants.HEIGHT]
            x: StyleSheetBrowseMap.bottom_area[Constants.X]
            y: StyleSheetBrowseMap.bottom_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: bottom
                opacity: 0.8
                image:StyleSheetBrowseMapBottom.navigation_app_browse_map_bottom_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                StdButton {
                    source:StyleSheetBrowseMapBottom.menub[Constants.SOURCE]; x:StyleSheetBrowseMapBottom.menub[Constants.X]; y:StyleSheetBrowseMapBottom.menub[Constants.Y]; width:StyleSheetBrowseMapBottom.menub[Constants.WIDTH]; height:StyleSheetBrowseMapBottom.menub[Constants.HEIGHT];textColor:StyleSheetBrowseMapBottom.menubText[Constants.TEXTCOLOR]; pixelSize:StyleSheetBrowseMapBottom.menubText[Constants.PIXELSIZE];
                    id:menub; text:Genivi.gettext("Back");
                    onClicked: {
                        disconnectSignals();
                        if (Genivi.entrybackheapsize){
                            Genivi.preloadMode=true;
                            leaveMenu(dltIf);
                        }
                        else
                            entryMenu(dltIf,"NavigationAppMain",menu);
                    }
                }

                SmartText {
                    x:StyleSheetBrowseMapBottom.currentroad[Constants.X]; y:StyleSheetBrowseMapBottom.currentroad[Constants.Y]; width:StyleSheetBrowseMapBottom.currentroad[Constants.WIDTH]; height:StyleSheetBrowseMapBottom.currentroad[Constants.HEIGHT];color:StyleSheetBrowseMapBottom.currentroad[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapBottom.currentroad[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapBottom.currentroad[Constants.PIXELSIZE];
                    visible: true
                    id:currentroad
                    text: "-------"
                }

                StdButton {
                    source:StyleSheetBrowseMapBottom.settings[Constants.SOURCE]; x:StyleSheetBrowseMapBottom.settings[Constants.X]; y:StyleSheetBrowseMapBottom.settings[Constants.Y]; width:StyleSheetBrowseMapBottom.settings[Constants.WIDTH]; height:StyleSheetBrowseMapBottom.settings[Constants.HEIGHT];
                    id:settings;
                    onClicked: {
                        disconnectSignals();
                        entryMenu(dltIf,"NavigationAppSettings",menu);
                    }
                }

                StdButton {
                    source:StyleSheetBrowseMapBottom.calculate_curr[Constants.SOURCE]; x:StyleSheetBrowseMapBottom.calculate_curr[Constants.X]; y:StyleSheetBrowseMapBottom.calculate_curr[Constants.Y]; width:StyleSheetBrowseMapBottom.calculate_curr[Constants.WIDTH]; height:StyleSheetBrowseMapBottom.calculate_curr[Constants.HEIGHT];
                    id:calculate_curr;
                    onClicked: {
                        if(Genivi.data['display_on_map']==='show_route')
                        {
                            // launch the guidance now !
                            startGuidance();
                        }else{
                            if(Genivi.data['display_on_map']==='show_position')
                            {
                                // launch a route calculation now !
                                // the guidance will be started if the route is successfully calculated
                                Genivi.data['destination']=Genivi.data['position'];
                                //create a route
                                var res4=Genivi.routing_CreateRoute(dbusIf,dltIf);
                                Genivi.g_routing_handle[1]=res4[3];
                                launchRouteCalculation();
                            }
                            else{
                                if(mapSettings.visible===true)
                                    hideMapSettingsPanel();
                                else {
                                    Genivi.mapmatchedposition_PauseSimulation(dbusIf,dltIf);
                                    showMapSettingsPanel();
                                }
                            }
                        }
                    }
                }

                StdButton {
                    x:StyleSheetBrowseMapBottom.mapExploration[Constants.X]; y:StyleSheetBrowseMapBottom.mapExploration[Constants.Y]; width:StyleSheetBrowseMapBottom.mapExploration[Constants.WIDTH]; height:StyleSheetBrowseMapBottom.mapExploration[Constants.HEIGHT];
                    id:exploration;
                    disabled:false;
                    source:StyleSheetBrowseMapBottom.gobackCurrent[Constants.SOURCE]; //todo call get status
                    property int status: 0;
                    function setState(name)
                    { //the icon displayed is the one of the current state
                        if (name=="E")
                        {
                            status=1;
                            source=StyleSheetBrowseMapBottom.mapExploration[Constants.SOURCE];
                        }
                        else
                        {
                            if (name=="C")
                            {
                                status=0;
                                source=StyleSheetBrowseMapBottom.gobackCurrent[Constants.SOURCE];
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
            width: StyleSheetBrowseMapRoute.navigation_app_browse_map_route_background[Constants.WIDTH]
            height: StyleSheetBrowseMapRoute.navigation_app_browse_map_route_background[Constants.HEIGHT]
            x: StyleSheetBrowseMap.route_area[Constants.X]
            y: StyleSheetBrowseMap.route_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: route
                opacity: 0.8
                image:StyleSheetBrowseMapRoute.navigation_app_browse_map_route_background[Constants.SOURCE]
                anchors { fill: parent; topMargin: parent.headlineHeight}
                StdButton {
                    source:StyleSheetBrowseMapRoute.show_maneuver_list[Constants.SOURCE]; x:StyleSheetBrowseMapRoute.show_maneuver_list[Constants.X]; y:StyleSheetBrowseMapRoute.show_maneuver_list[Constants.Y]; width:StyleSheetBrowseMapRoute.show_maneuver_list[Constants.WIDTH]; height:StyleSheetBrowseMapRoute.show_maneuver_list[Constants.HEIGHT];
                    id:maneuverList;
                    disabled:false;
                    onClicked: {
                        if(Genivi.guidance_activated)
                            showManeuversListPanel();
                    }
                }
                Text {
                    x:StyleSheetBrowseMapRoute.timeofarrivalValue[Constants.X]; y:StyleSheetBrowseMapRoute.timeofarrivalValue[Constants.Y]; width:StyleSheetBrowseMapRoute.timeofarrivalValue[Constants.WIDTH]; height:StyleSheetBrowseMapRoute.timeofarrivalValue[Constants.HEIGHT];color:StyleSheetBrowseMapRoute.timeofarrivalValue[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapRoute.timeofarrivalValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapRoute.timeofarrivalValue[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:timeofarrivalValue
                    text: "-------"
                }
                Text {
                    x:StyleSheetBrowseMapRoute.distancetodestinationValue[Constants.X]; y:StyleSheetBrowseMapRoute.distancetodestinationValue[Constants.Y]; width:StyleSheetBrowseMapRoute.distancetodestinationValue[Constants.WIDTH]; height:StyleSheetBrowseMapRoute.distancetodestinationValue[Constants.HEIGHT];color:StyleSheetBrowseMapRoute.distancetodestinationValue[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapRoute.distancetodestinationValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapRoute.distancetodestinationValue[Constants.PIXELSIZE];
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
            width: StyleSheetBrowseMapGuidance.navigation_app_browse_map_guidance_background[Constants.WIDTH]
            height: StyleSheetBrowseMapGuidance.navigation_app_browse_map_guidance_background[Constants.HEIGHT]
            x: StyleSheetBrowseMap.guidance_area[Constants.X]
            y: StyleSheetBrowseMap.guidance_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: guidance
                opacity: 0.8
                image:StyleSheetBrowseMapGuidance.navigation_app_browse_map_guidance_background[Constants.SOURCE]
                anchors { fill: parent; topMargin: parent.headlineHeight}
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if(Genivi.guidance_activated)
                            showManeuversListPanel();
                    }
                }

                Text {
                    x:StyleSheetBrowseMapGuidance.distancetomaneuverValue[Constants.X]; y:StyleSheetBrowseMapGuidance.distancetomaneuverValue[Constants.Y]; width:StyleSheetBrowseMapGuidance.distancetomaneuverValue[Constants.WIDTH]; height:StyleSheetBrowseMapGuidance.distancetomaneuverValue[Constants.HEIGHT];color:StyleSheetBrowseMapGuidance.distancetomaneuverValue[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapGuidance.distancetomaneuverValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapGuidance.distancetomaneuverValue[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:distancetomaneuverValue
                    text: " "
                }

                SmartText {
                    x:StyleSheetBrowseMapGuidance.roadaftermaneuverValue[Constants.X]; y:StyleSheetBrowseMapGuidance.roadaftermaneuverValue[Constants.Y]; width:StyleSheetBrowseMapGuidance.roadaftermaneuverValue[Constants.WIDTH]; height:StyleSheetBrowseMapGuidance.roadaftermaneuverValue[Constants.HEIGHT];color:StyleSheetBrowseMapGuidance.roadaftermaneuverValue[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapGuidance.roadaftermaneuverValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapGuidance.roadaftermaneuverValue[Constants.PIXELSIZE];
                    visible: true
                    id:roadaftermaneuverValue
                    text: " "
                }

                BorderImage {
                    id: maneuverBarAdv
                    source:StyleSheetBrowseMapGuidance.maneuverBarAdv[Constants.SOURCE]; x:StyleSheetBrowseMapGuidance.maneuverBarAdv[Constants.X]; y:StyleSheetBrowseMapGuidance.maneuverBarAdv[Constants.Y]; width:StyleSheetBrowseMapGuidance.maneuverBarAdv[Constants.WIDTH]; height:StyleSheetBrowseMapGuidance.maneuverBarAdv[Constants.HEIGHT];
                    visible: false
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                }
                BorderImage {
                    id: maneuverBarPre
                    source:StyleSheetBrowseMapGuidance.maneuverBarPre[Constants.SOURCE]; x:StyleSheetBrowseMapGuidance.maneuverBarPre[Constants.X]; y:StyleSheetBrowseMapGuidance.maneuverBarPre[Constants.Y]; width:StyleSheetBrowseMapGuidance.maneuverBarPre[Constants.WIDTH]; height:StyleSheetBrowseMapGuidance.maneuverBarPre[Constants.HEIGHT];
                    visible: false
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                }
                BorderImage {
                    id: maneuverBarApp
                    source:StyleSheetBrowseMapGuidance.maneuverBarApp[Constants.SOURCE]; x:StyleSheetBrowseMapGuidance.maneuverBarApp[Constants.X]; y:StyleSheetBrowseMapGuidance.maneuverBarApp[Constants.Y]; width:StyleSheetBrowseMapGuidance.maneuverBarApp[Constants.WIDTH]; height:StyleSheetBrowseMapGuidance.maneuverBarApp[Constants.HEIGHT];
                    visible: false
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                }
                BorderImage {
                    id: maneuverBarCru
                    source:StyleSheetBrowseMapGuidance.maneuverBarCru[Constants.SOURCE]; x:StyleSheetBrowseMapGuidance.maneuverBarCru[Constants.X]; y:StyleSheetBrowseMapGuidance.maneuverBarCru[Constants.Y]; width:StyleSheetBrowseMapGuidance.maneuverBarCru[Constants.WIDTH]; height:StyleSheetBrowseMapGuidance.maneuverBarCru[Constants.HEIGHT];
                    visible: false
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                }

                BorderImage {
                    id: maneuverIcon
                    source:StyleSheetBrowseMapGuidance.maneuverIcon[Constants.SOURCE]; x:StyleSheetBrowseMapGuidance.maneuverIcon[Constants.X]; y:StyleSheetBrowseMapGuidance.maneuverIcon[Constants.Y]; width:StyleSheetBrowseMapGuidance.maneuverIcon[Constants.WIDTH]; height:StyleSheetBrowseMapGuidance.maneuverIcon[Constants.HEIGHT];
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetBrowseMapScroll.navigation_app_browse_map_scroll_background[Constants.WIDTH]
            height: StyleSheetBrowseMapScroll.navigation_app_browse_map_scroll_background[Constants.HEIGHT]
            x: StyleSheetBrowseMap.scroll_area[Constants.X]
            y: StyleSheetBrowseMap.scroll_area[Constants.Y]
            NavigationAppHMIBgImage {
                opacity: 0.8
                property real panX: 40 //delta in pixel for x panning
                property real panY: 40 //delta in pixel for y panning
                id: scroll
                image:StyleSheetBrowseMapScroll.navigation_app_browse_map_scroll_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                StdButton {
                    source:StyleSheetBrowseMapScroll.scrollup[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.scrollup[Constants.X]; y:StyleSheetBrowseMapScroll.scrollup[Constants.Y]; width:StyleSheetBrowseMapScroll.scrollup[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.scrollup[Constants.HEIGHT];
                    id:scrollup;
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_END,map.width/2,map.height/2 + scroll.panY);}
                }

                StdButton {
                    source:StyleSheetBrowseMapScroll.scrollleft[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.scrollleft[Constants.X]; y:StyleSheetBrowseMapScroll.scrollleft[Constants.Y]; width:StyleSheetBrowseMapScroll.scrollleft[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.scrollleft[Constants.HEIGHT];
                    id:scrollleft;
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_END,map.width/2 + scroll.panX,map.height/2);}
                }

                StdButton {
                    source:StyleSheetBrowseMapScroll.scrollright[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.scrollright[Constants.X]; y:StyleSheetBrowseMapScroll.scrollright[Constants.Y]; width:StyleSheetBrowseMapScroll.scrollright[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.scrollright[Constants.HEIGHT];
                    id:scrollright;
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_END,map.width/2 - scroll.panX,map.height/2);}
                }

                StdButton {
                    source:StyleSheetBrowseMapScroll.scrolldown[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.scrolldown[Constants.X]; y:StyleSheetBrowseMapScroll.scrolldown[Constants.Y]; width:StyleSheetBrowseMapScroll.scrolldown[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.scrolldown[Constants.HEIGHT];
                    id:scrolldown;
                    onPressed: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_START,map.width/2,map.height/2);}
                    onReleased: {Genivi.mapviewer_SetMapViewPan(dbusIf,dltIf,Genivi.MAPVIEWER_PAN_END,map.width/2,map.height/2 - scroll.panY);}
                }

                StdButton {
                    source:StyleSheetBrowseMapScroll.rotateClockwize[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.rotateClockwize[Constants.X]; y:StyleSheetBrowseMapScroll.rotateClockwize[Constants.Y]; width:StyleSheetBrowseMapScroll.rotateClockwize[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.rotateClockwize[Constants.HEIGHT];
                    id:rotateClockwize;
                    onPressed: {rotation_start(false);}
                    onReleased: {rotation_stop();}
                }

                StdButton {
                    source:StyleSheetBrowseMapScroll.rotateAntiClockwize[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.rotateAntiClockwize[Constants.X]; y:StyleSheetBrowseMapScroll.rotateAntiClockwize[Constants.Y]; width:StyleSheetBrowseMapScroll.rotateAntiClockwize[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.rotateAntiClockwize[Constants.HEIGHT];
                    id:rotateAntiClockwize;
                    onPressed: {rotation_start(true);}
                    onReleased: {rotation_stop();}
                }

                BorderImage {
                    id: threeDSettings
                    source:StyleSheetBrowseMapScroll.threeDSettings[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.threeDSettings[Constants.X]; y:StyleSheetBrowseMapScroll.threeDSettings[Constants.Y]; width:StyleSheetBrowseMapScroll.threeDSettings[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.threeDSettings[Constants.HEIGHT];
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                }

                Text {
                    x:StyleSheetBrowseMapScroll.tiltText[Constants.X]; y:StyleSheetBrowseMapScroll.tiltText[Constants.Y]; width:StyleSheetBrowseMapScroll.tiltText[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.tiltText[Constants.HEIGHT];color:StyleSheetBrowseMapScroll.tiltText[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapScroll.tiltText[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapScroll.tiltText[Constants.PIXELSIZE];
                    id:tiltText;
                    style: Text.Sunken;
                    smooth: true
                    text: Genivi.gettext("CameraTilt")
                     }
                StdButton {
                    source:StyleSheetBrowseMapScroll.tiltp[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.tiltp[Constants.X]; y:StyleSheetBrowseMapScroll.tiltp[Constants.Y]; width:StyleSheetBrowseMapScroll.tiltp[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.tiltp[Constants.HEIGHT];
                           id:tiltp;
                        onPressed: {camera_start_clamp("CameraTiltAngle",-10,0);}
                        onReleased: {camera_stop();}
                }
                StdButton {
                    source:StyleSheetBrowseMapScroll.tiltm[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.tiltm[Constants.X]; y:StyleSheetBrowseMapScroll.tiltm[Constants.Y]; width:StyleSheetBrowseMapScroll.tiltm[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.tiltm[Constants.HEIGHT];
                    id:tiltm;
                    onPressed: {camera_start_clamp("CameraTiltAngle",10,90);}
                    onReleased: {camera_stop();}
                }

                Text {
                    x:StyleSheetBrowseMapScroll.heightText[Constants.X]; y:StyleSheetBrowseMapScroll.heightText[Constants.Y]; width:StyleSheetBrowseMapScroll.heightText[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.heightText[Constants.HEIGHT];color:StyleSheetBrowseMapScroll.heightText[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapScroll.heightText[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapScroll.heightText[Constants.PIXELSIZE];
                    id:heightText;
                    style: Text.Sunken;
                    smooth: true
                    text: Genivi.gettext("CameraHeight")
                     }
                StdButton {
                    source:StyleSheetBrowseMapScroll.heightp[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.heightp[Constants.X]; y:StyleSheetBrowseMapScroll.heightp[Constants.Y]; width:StyleSheetBrowseMapScroll.heightp[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.heightp[Constants.HEIGHT];
                    id:heightp;
                    onPressed: {camera_start("CameraHeight",10);}
                    onReleased: {camera_stop();}
                }
                StdButton {
                    source:StyleSheetBrowseMapScroll.heightm[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.heightm[Constants.X]; y:StyleSheetBrowseMapScroll.heightm[Constants.Y]; width:StyleSheetBrowseMapScroll.heightm[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.heightm[Constants.HEIGHT];
                    id:heightm;
                    onPressed: {camera_start("CameraHeight",-10);}
                    onReleased: {camera_stop();}
                }

                Text {
                    x:StyleSheetBrowseMapScroll.distanceText[Constants.X]; y:StyleSheetBrowseMapScroll.distanceText[Constants.Y]; width:StyleSheetBrowseMapScroll.distanceText[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.distanceText[Constants.HEIGHT];color:StyleSheetBrowseMapScroll.distanceText[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapScroll.distanceText[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapScroll.distanceText[Constants.PIXELSIZE];
                    id:distanceText;
                    style: Text.Sunken;
                    smooth: true
                    text: Genivi.gettext("CameraDistance")
                     }
                StdButton {
                    source:StyleSheetBrowseMapScroll.distancep[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.distancep[Constants.X]; y:StyleSheetBrowseMapScroll.distancep[Constants.Y]; width:StyleSheetBrowseMapScroll.distancep[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.distancep[Constants.HEIGHT];
                    id:distancep;
                    onPressed: {camera_start("CameraDistanceFromTargetPoint",10);}
                    onReleased: {camera_stop();}
                }
                StdButton {
                    source:StyleSheetBrowseMapScroll.distancem[Constants.SOURCE]; x:StyleSheetBrowseMapScroll.distancem[Constants.X]; y:StyleSheetBrowseMapScroll.distancem[Constants.Y]; width:StyleSheetBrowseMapScroll.distancem[Constants.WIDTH]; height:StyleSheetBrowseMapScroll.distancem[Constants.HEIGHT];
                           id:distancem;
                        onPressed: {camera_start("CameraDistanceFromTargetPoint",-10);}
                        onReleased: {camera_stop();}
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetBrowseMapZoom.navigation_app_browse_map_zoom_background[Constants.WIDTH]
            height: StyleSheetBrowseMapZoom.navigation_app_browse_map_zoom_background[Constants.HEIGHT]
            x: StyleSheetBrowseMap.zoom_area[Constants.X]
            y: StyleSheetBrowseMap.zoom_area[Constants.Y]
            NavigationAppHMIBgImage {
                opacity: 0.8
                id: zoom
                image:StyleSheetBrowseMapZoom.navigation_app_browse_map_zoom_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                StdButton {
                    source:StyleSheetBrowseMapZoom.zoomin[Constants.SOURCE]; x:StyleSheetBrowseMapZoom.zoomin[Constants.X]; y:StyleSheetBrowseMapZoom.zoomin[Constants.Y]; width:StyleSheetBrowseMapZoom.zoomin[Constants.WIDTH]; height:StyleSheetBrowseMapZoom.zoomin[Constants.HEIGHT];
                    id:zoomin;
                    onClicked: {
                        if(Genivi.currentZoomId>Genivi.minZoomId){
                            Genivi.mapviewer_SetMapViewScaleByDelta(dbusIf,dltIf,-1);
                        }
                    }
                }

                StdButton {
                    source:StyleSheetBrowseMapZoom.zoomout[Constants.SOURCE]; x:StyleSheetBrowseMapZoom.zoomout[Constants.X]; y:StyleSheetBrowseMapZoom.zoomout[Constants.Y]; width:StyleSheetBrowseMapZoom.zoomout[Constants.WIDTH]; height:StyleSheetBrowseMapZoom.zoomout[Constants.HEIGHT];
                    id:zoomout;
                    onClicked: {
                        if(Genivi.currentZoomId<Genivi.maxZoomId){
                            Genivi.mapviewer_SetMapViewScaleByDelta(dbusIf,dltIf,1);
                        }
                    }
                }

            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetBrowseMapCompass.navigation_app_browse_map_compass_background[Constants.WIDTH]
            height: StyleSheetBrowseMapCompass.navigation_app_browse_map_compass_background[Constants.HEIGHT]
            x: StyleSheetBrowseMap.compass_area[Constants.X]
            y: StyleSheetBrowseMap.compass_area[Constants.Y]
            NavigationAppHMIBgImage {
                opacity: 0.8
                id: compass
                image:StyleSheetBrowseMapCompass.navigation_app_browse_map_compass_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}

                StdButton {
                    x:StyleSheetBrowseMapCompass.directiondestination[Constants.X]; y:StyleSheetBrowseMapCompass.directiondestination[Constants.Y]; width:StyleSheetBrowseMapCompass.directiondestination[Constants.WIDTH]; height:StyleSheetBrowseMapCompass.directiondestination[Constants.HEIGHT];
                    id:orientation;
                    disabled:false;
                    source:StyleSheetBrowseMapCompass.directionnorth[Constants.SOURCE]; //todo call get status
                    property int status: 0;
                    function setState(name)
                    { //the icon displayed is the one of the current state
                        if (name=="N")
                        {
                            status=0;
                            source=StyleSheetBrowseMapCompass.directionnorth[Constants.SOURCE];
                        }
                        else
                        {
                            if (name=="D")
                            {
                                status=1;
                                source=StyleSheetBrowseMapCompass.directiondestination[Constants.SOURCE];
                            }
                            else
                            {
                                if (name=="B")
                                {
                                    status=2;
                                    source=StyleSheetBrowseMapCompass.directionThreeD[Constants.SOURCE];
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
            width: StyleSheetBrowseMapSimulation.navigation_app_browse_map_simulation_background[Constants.WIDTH]
            height: StyleSheetBrowseMapSimulation.navigation_app_browse_map_simulation_background[Constants.HEIGHT]
            x: StyleSheetBrowseMap.simulation_area[Constants.X]
            y: StyleSheetBrowseMap.simulation_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: simulation
                opacity: 0.8
                image:StyleSheetBrowseMapSimulation.navigation_app_browse_map_simulation_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}
                Text {
                    x:StyleSheetBrowseMapSimulation.speedValue[Constants.X]; y:StyleSheetBrowseMapSimulation.speedValue[Constants.Y]; width:StyleSheetBrowseMapSimulation.speedValue[Constants.WIDTH]; height:StyleSheetBrowseMapSimulation.speedValue[Constants.HEIGHT];color:StyleSheetBrowseMapSimulation.speedValue[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapSimulation.speedValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapSimulation.speedValue[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:vehicleSpeedValue
                    text: "---"
                }

                Text {
                    x:StyleSheetBrowseMapSimulation.speedUnit[Constants.X]; y:StyleSheetBrowseMapSimulation.speedUnit[Constants.Y]; width:StyleSheetBrowseMapSimulation.speedUnit[Constants.WIDTH]; height:StyleSheetBrowseMapSimulation.speedUnit[Constants.HEIGHT];color:StyleSheetBrowseMapSimulation.speedUnit[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapSimulation.speedUnit[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapSimulation.speedUnit[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:speedUnit
                    text: "km/h"
                }
                StdButton {
                    source:StyleSheetBrowseMapSimulation.speed_down_popup[Constants.SOURCE]; x:StyleSheetBrowseMapSimulation.speed_down_popup[Constants.X]; y:StyleSheetBrowseMapSimulation.speed_down_popup[Constants.Y]; width:StyleSheetBrowseMapSimulation.speed_down_popup[Constants.WIDTH]; height:StyleSheetBrowseMapSimulation.speed_down_popup[Constants.HEIGHT];
                    id:speed_down;  disabled:false;
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
                    source:StyleSheetBrowseMapSimulation.speed_up_popup[Constants.SOURCE]; x:StyleSheetBrowseMapSimulation.speed_up_popup[Constants.X]; y:StyleSheetBrowseMapSimulation.speed_up_popup[Constants.Y]; width:StyleSheetBrowseMapSimulation.speed_up_popup[Constants.WIDTH]; height:StyleSheetBrowseMapSimulation.speed_up_popup[Constants.HEIGHT];
                    id:speed_up;  disabled:false;
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
                    x:StyleSheetBrowseMapSimulation.play_popup[Constants.X]; y:StyleSheetBrowseMapSimulation.play_popup[Constants.Y]; width:StyleSheetBrowseMapSimulation.play_popup[Constants.WIDTH]; height:StyleSheetBrowseMapSimulation.play_popup[Constants.HEIGHT];
                    id:simu_mode;
                    disabled:false;
                    property int status: 0;
                    function setState(name)
                    {
                        if (name=="FREE")
                        {
                            status=0;
                            source=StyleSheetBrowseMapSimulation.play_popup[Constants.SOURCE];
                            disabled=true;
                        }
                        else
                        {
                            if (name=="PLAY")
                            {
                                status=1;
                                source=StyleSheetBrowseMapSimulation.pause_popup[Constants.SOURCE];
                                enabled=true;
                                disabled=false;
                            }
                            else
                            {
                                if (name=="PAUSE")
                                {
                                    status=2;
                                    source=StyleSheetBrowseMapSimulation.play_popup[Constants.SOURCE];
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
            width: StyleSheetBrowseMapManeuver.navigation_app_browse_map_maneuver_background[Constants.WIDTH]
            height: StyleSheetBrowseMapManeuver.navigation_app_browse_map_maneuver_background[Constants.HEIGHT]
            x: StyleSheetBrowseMap.maneuver_area[Constants.X]
            y: StyleSheetBrowseMap.maneuver_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: maneuver
                opacity: 0.8
                visible: (displayManeuvers)
                image:StyleSheetBrowseMapManeuver.navigation_app_browse_map_maneuver_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}
                StdButton {
                    source:StyleSheetBrowseMapManeuver.exit[Constants.SOURCE]; x:StyleSheetBrowseMapManeuver.exit[StyleSheetBrowseMapManeuver.X]; y:StyleSheetBrowseMapManeuver.exit[StyleSheetBrowseMapManeuver.Y]; width:StyleSheetBrowseMapManeuver.exit[StyleSheetBrowseMapManeuver.WIDTH]; height:StyleSheetBrowseMapManeuver.exit[StyleSheetBrowseMapManeuver.HEIGHT];
                    id:exit;
                    onClicked: { hideManeuversListPanel(); }
                }
                Component {
                    id: maneuverDelegate
                    Text {
                        width:StyleSheetBrowseMapManeuver.maneuver_delegate[Constants.WIDTH]; height:StyleSheetBrowseMapManeuver.maneuver_delegate[Constants.HEIGHT];color:StyleSheetBrowseMapManeuver.maneuver_delegate[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapManeuver.maneuver_delegate[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapManeuver.maneuver_delegate[Constants.PIXELSIZE];
                        id:maneuverItem;
                        text: name;
                        style: Text.Sunken;
                        smooth: true
                    }
                }
                NavigationAppHMIList {
                    property real selectedEntry
                    x:StyleSheetBrowseMapManeuver.maneuver_area[Constants.X]; y:StyleSheetBrowseMapManeuver.maneuver_area[Constants.Y]; width:StyleSheetBrowseMapManeuver.maneuver_area[Constants.WIDTH]; height:StyleSheetBrowseMapManeuver.maneuver_area[Constants.HEIGHT];
                    id:maneuverArea
                    delegate: maneuverDelegate
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetBrowseMapScale.navigation_app_browse_map_scale_background[Constants.WIDTH]
            height: StyleSheetBrowseMapScale.navigation_app_browse_map_scale_background[Constants.HEIGHT]
            x: StyleSheetBrowseMap.scale_area[Constants.X]
            y: StyleSheetBrowseMap.scale_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: scale
                opacity: 1
                image:StyleSheetBrowseMapScale.navigation_app_browse_map_scale_background[Constants.SOURCE]
                anchors { fill: parent; topMargin: parent.headlineHeight}
                Text {
                    x:StyleSheetBrowseMapScale.scaleValue[Constants.X]; y:StyleSheetBrowseMapScale.scaleValue[Constants.Y]; width:StyleSheetBrowseMapScale.scaleValue[Constants.WIDTH]; height:StyleSheetBrowseMapScale.scaleValue[Constants.HEIGHT];color:StyleSheetBrowseMapScale.scaleValue[Constants.TEXTCOLOR];styleColor:StyleSheetBrowseMapScale.scaleValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheetBrowseMapScale.scaleValue[Constants.PIXELSIZE];
                    visible: true
                    style: Text.Sunken;
                    smooth: true
                    id:scaleValue
                    text: "-------"
                }
                BorderImage {
                    id: left
                    source: StyleSheetBrowseMapScale.left[Constants.SOURCE];x:StyleSheetBrowseMapScale.left[Constants.X]; y:StyleSheetBrowseMapScale.left[Constants.Y]; width:StyleSheetBrowseMapScale.left[Constants.WIDTH]; height:StyleSheetBrowseMapScale.left[Constants.HEIGHT];
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                    visible: true;
                }
                BorderImage {
                    id: scale_bar
                    source: StyleSheetBrowseMapScale.scale_bar[Constants.SOURCE];x:StyleSheetBrowseMapScale.scale_bar[Constants.X]; y:StyleSheetBrowseMapScale.scale_bar[Constants.Y]; width:StyleSheetBrowseMapScale.scale_bar[Constants.WIDTH]; height:StyleSheetBrowseMapScale.scale_bar[Constants.HEIGHT];
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                    visible: true;
                }
                BorderImage {
                    id: right
                    source: StyleSheetBrowseMapScale.right[Constants.SOURCE];x:StyleSheetBrowseMapScale.right[Constants.X]; y:StyleSheetBrowseMapScale.right[Constants.Y]; width:StyleSheetBrowseMapScale.right[Constants.WIDTH]; height:StyleSheetBrowseMapScale.right[Constants.HEIGHT];
                    border.left: 0; border.top: 0
                    border.right: 0; border.bottom: 0
                    visible: true;
                }
            }
        }

        Rectangle {
            color:"transparent"
            width: StyleSheetBrowseMapSettings.navigation_app_browse_map_settings_background[Constants.WIDTH]
            height: StyleSheetBrowseMapSettings.navigation_app_browse_map_settings_background[Constants.HEIGHT]
            x: StyleSheetBrowseMap.settings_area[Constants.X]
            y: StyleSheetBrowseMap.settings_area[Constants.Y]
            NavigationAppHMIBgImage {
                id: mapSettings
                opacity: 0.8
                image:StyleSheetBrowseMapSettings.navigation_app_browse_map_settings_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}
                 StdButton {
                     source:StyleSheetBrowseMapSettings.restart[Constants.SOURCE]; x:StyleSheetBrowseMapSettings.restart[Constants.X]; y:StyleSheetBrowseMapSettings.restart[Constants.Y]; width:StyleSheetBrowseMapSettings.restart[Constants.WIDTH]; height:StyleSheetBrowseMapSettings.restart[Constants.HEIGHT];textColor:StyleSheetBrowseMapSettings.restartText[Constants.TEXTCOLOR]; pixelSize:StyleSheetBrowseMapSettings.restartText[Constants.PIXELSIZE];
                     id:restartGuidance;
                     text: Genivi.gettext("Restart")
                     disabled: (Genivi.guidance_activated || !Genivi.route_calculated);
                     onPressed: {
                         //restart guidance (the route is displayed when the menu is reloaded due to guidance status changed)
                         startGuidance();
                     }
                 }
                 StdButton {
                     source:StyleSheetBrowseMapSettings.cancel[Constants.SOURCE]; x:StyleSheetBrowseMapSettings.cancel[Constants.X]; y:StyleSheetBrowseMapSettings.cancel[Constants.Y]; width:StyleSheetBrowseMapSettings.cancel[Constants.WIDTH]; height:StyleSheetBrowseMapSettings.cancel[Constants.HEIGHT];textColor:StyleSheetBrowseMapSettings.cancelText[Constants.TEXTCOLOR]; pixelSize:StyleSheetBrowseMapSettings.cancelText[Constants.PIXELSIZE];
                     id:cancel;
                     text: Genivi.gettext("Cancel")
                     disabled: !(Genivi.guidance_activated);
                     onPressed: {
                        //stop guidance
                         Genivi.guidance_StopGuidance(dbusIf,dltIf);
                         //Guidance inactive, so inform the trip computer
                         Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,0,0);
                         Genivi.mapviewer_HideRoute(dbusIf,dltIf,Genivi.g_routing_handle);
                     }
                 }
                 StdButton {
                     source:StyleSheetBrowseMapSettings.location_input[Constants.SOURCE]; x:StyleSheetBrowseMapSettings.location_input[Constants.X]; y:StyleSheetBrowseMapSettings.location_input[Constants.Y]; width:StyleSheetBrowseMapSettings.location_input[Constants.WIDTH]; height:StyleSheetBrowseMapSettings.location_input[Constants.HEIGHT];
                     id:location_input;
                     onPressed: {
                         disconnectSignals();
                         exitRoute();
                         //the location is entered by address
                         Genivi.setLocationInputActivated(dltIf,true);
                         Genivi.preloadMode=true;
                         entryMenu(dltIf,"NavigationAppSearch",menu);
                     }
                 }
                 StdButton {
                     source:StyleSheetBrowseMapSettings.poi[Constants.SOURCE]; x:StyleSheetBrowseMapSettings.poi[Constants.X]; y:StyleSheetBrowseMapSettings.poi[Constants.Y]; width:StyleSheetBrowseMapSettings.poi[Constants.WIDTH]; height:StyleSheetBrowseMapSettings.poi[Constants.HEIGHT];
                     id:poi;
                     onPressed: {
                        disconnectSignals();
                        exitRoute();
                        // the location is entered by poi
                        Genivi.setLocationInputActivated(dltIf,false);
                        entryMenu(dltIf,"NavigationAppPOI",menu);
                     }
                 }
                 StdButton {
                     source:StyleSheetBrowseMapSettings.exit[Constants.SOURCE]; x:StyleSheetBrowseMapSettings.exit[StyleSheetBrowseMapSettings.X]; y:StyleSheetBrowseMapSettings.exit[StyleSheetBrowseMapSettings.Y]; width:StyleSheetBrowseMapSettings.exit[StyleSheetBrowseMapSettings.WIDTH]; height:StyleSheetBrowseMapSettings.exit[StyleSheetBrowseMapSettings.HEIGHT];
                     id:exitSettings;
                     onPressed: {
                        hideMapSettingsPanel();
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
            Genivi.mapviewer_DisplayRoute(dbusIf,dltIf,Genivi.g_routing_handle,false);
            Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,1,50); //activate advisor mode
            hideGuidancePanel();
            hideRoutePanel();
            hideSimulationPanel();
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
                    Genivi.mapviewer_DisplayRoute(dbusIf,dltIf,Genivi.g_routing_handle,false);
                    Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,1,50); //activate advisor mode
                    showGuidancePanel();
                    showRoutePanel();
                    updateGuidance();
                    Genivi.mapmatchedposition_SetSimulationMode(dbusIf,dltIf,Genivi.simulationMode);
                    if (Genivi.simulationMode===true)
                    {
                        Genivi.mapmatchedposition_PauseSimulation(dbusIf,dltIf);
                        showSimulationPanel();
                        updateSimulation();
                    } else {
                        hideSimulationPanel();
                    }
                } else {
                    if(Genivi.showroom) {
                        Genivi.data['current_position']=Genivi.data['default_position'];
                    }
                    Genivi.mapviewer_SetTargetPoint(dbusIf,dltIf,Genivi.data['current_position']['lat'],Genivi.data['current_position']['lon'],Genivi.data['current_position']['alt']);
                    Genivi.fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,dltIf,0,50); //no advisor mode
                    Genivi.mapmatchedposition_SetSimulationMode(dbusIf,dltIf,Genivi.simulationMode);
                    if (Genivi.simulationMode===true)
                    {
                        Genivi.mapmatchedposition_PauseSimulation(dbusIf,dltIf);
                    }
                    hideGuidancePanel();
                    hideRoutePanel();
                    hideSimulationPanel();
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
                    Genivi.mapmatchedposition_SetSimulationMode(dbusIf,dltIf,Genivi.simulationMode);
                    if (Genivi.simulationMode===true)
                    {
                        Genivi.mapmatchedposition_PauseSimulation(dbusIf,dltIf);
                    }
                    hideGuidancePanel();
                    hideRoutePanel();
                    hideSimulationPanel();
                    updateAddress(); //there's a pb of accuracy of SetPosition in mapmatchedposition
                }
            }
        }

        hideMapSettingsPanel();
        hideScrollPanel();
        hideThreeDSettingsPanel();
        exploration.setState("C");
        showZoom();
	}
}
