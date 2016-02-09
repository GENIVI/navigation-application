/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationSearchAddress.qml
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
.pragma library

Qt.include("resource.js")

var dbusIf;
var g_nav_session;
var g_loc_handle;
var g_routing_handle;
var g_map_session;
var g_map_handle;
var g_map_handle2;
var g_poisearch_handle;
var g_lang;

var data=new Array;

var poi_data=new Array;
var poi_id;

var translations=new Array;

var simulationPanelOnMapview=true;// simulation panel on map view by default

var guidance_activated=false; //used by the HMI to directly go to map when guidance is on (reroute use case)
var route_calculated=false; //no route (managed by NavigationRoute and NavigationCalculatedRoute)

var entryback = new Array;
var entrybackheapsize=0;
entryback[entrybackheapsize]="";
var entrydest;
var entrycriterion;
var entryselectedentry;

var entrycancel = false; //set to true when back button is pushed without any selection

var Maneuver = new Object;
Maneuver[NAVIGATIONCORE_INVALID]="INV";
Maneuver[NAVIGATIONCORE_CRUISE]="CRU";
Maneuver[NAVIGATIONCORE_MANEUVER_APPEARED]="APP";
Maneuver[NAVIGATIONCORE_PRE_ADVICE]="PRE";
Maneuver[NAVIGATIONCORE_ADVICE]="ADV";
Maneuver[NAVIGATIONCORE_PASSED]="PAS";


var ManeuverType = new Object;
ManeuverType[NAVIGATIONCORE_INVALID]="INVALID";
ManeuverType[NAVIGATIONCORE_STRAIGHT_ON]="STRAIGHT_ON";
ManeuverType[NAVIGATIONCORE_CROSSROAD]="CROSSROAD";
ManeuverType[NAVIGATIONCORE_ROUNDABOUT]="ROUNDABOUT";
ManeuverType[NAVIGATIONCORE_HIGHWAY_ENTER]="HIGHWAY_ENTER";
ManeuverType[NAVIGATIONCORE_HIGHWAY_EXIT]="HIGHWAY_EXIT";
ManeuverType[NAVIGATIONCORE_FOLLOW_SPECIFIC_LANE]="FOLLOW_SPECIFIC_LANE";
ManeuverType[NAVIGATIONCORE_DESTINATION]="DESTINATION";
ManeuverType[NAVIGATIONCORE_WAYPOINT]="WAYPOINT";

var ManeuverDirection = new Object;
ManeuverDirection[NAVIGATIONCORE_INVALID]="INVALID";
ManeuverDirection[NAVIGATIONCORE_STRAIGHT_ON]="STRAIGHT_ON";
ManeuverDirection[NAVIGATIONCORE_LEFT]="LEFT";
ManeuverDirection[NAVIGATIONCORE_SLIGHT_LEFT]="SLIGHT_LEFT";
ManeuverDirection[NAVIGATIONCORE_HARD_LEFT]="HARD_LEFT";
ManeuverDirection[NAVIGATIONCORE_RIGHT]="RIGHT";
ManeuverDirection[NAVIGATIONCORE_SLIGHT_RIGHT]="SLIGHT_RIGHT";
ManeuverDirection[NAVIGATIONCORE_HARD_RIGHT]="HARD_RIGHT";
ManeuverDirection[NAVIGATIONCORE_UTURN_RIGHT]="UTURN_RIGHT";
ManeuverDirection[NAVIGATIONCORE_UTURN_LEFT]="UTURN_LEFT";

var CostModels = new Object;
CostModels[NAVIGATIONCORE_INVALID]="INVALID";
CostModels[NAVIGATIONCORE_FASTEST]="FASTEST";
CostModels[NAVIGATIONCORE_SHORTEST]="SHORTEST";

var preloadMode=false; //set to true when the address is restored
var address = new Object; //to store the address, in order to make the hmi more friendly :-)
var tripMode; //trip mode to be displayed by the trip computer menu ("TRIP_NUMBER1", "TRIP_NUMBER2" or "TRIP_INSTANT")
var historyOfLastEnteredLocationDepth;
var historyOfLastEnteredLocation = new Array; //to store the last entered locations (for consistency, it'd be nice to "remapmatch" it when the map is upadted)
var historyOfLastEnteredLat = new Array; //dirty but need to know how to do it in qml
var historyOfLastEnteredLon = new Array; //dirty but need to know how to do it in qml
var historyOfLastEnteredLocationIn=0; //next input
var historyOfLastEnteredLocationOut=0; //first ouput
var radius=5000; //radius in m around the vehicle to search for the refill stations
var offset=0; //offset of the start record to get on the list of pois
var maxWindowSize=20; //max size of elements to return as a result
var fuelCategoryId; //unique id of fuel category

//the default data below will be managed by the persistency component in the future
address[NAVIGATIONCORE_COUNTRY]="Switzerland";
address[NAVIGATIONCORE_CITY]="Zürich";
address[NAVIGATIONCORE_STREET]="In Lampitzäckern";
address[NAVIGATIONCORE_HOUSENUMBER]="";
historyOfLastEnteredLocationDepth=10; //max number of items into the history is set to historyOfLastEnteredLocationDepth-1
tripMode="TRIP_NUMBER1";

//dump functions for debug
function dump2(prefix,index,args)
{
	for (var i=0 ; i < args.length ; i+=2) {
		var i1=index+"["+i+"]";
		var i2=index+"["+(i+1)+"]";
		if (args[i] == "array" || args[i] == "map" || args[i] == "structure") {
			console.log(prefix+i1+args[i]+":");
			dump2(prefix,i2,args[i+1]);
		} else if (args[i] == "variant" || args[i] == "error") {
			dump2(prefix+i1+args[i]+":",i2,args[i+1]);
		} else {
			console.log(prefix+i1+args[i]+":"+i2+args[i+1]);
		}
	}
}

function dump(prefix,args)
{
	dump2(prefix,"",args);
}	

//Manage the historyOfLastEnteredLocation
function updateHistoryOfLastEnteredLocation(enteredLocation,enteredLat,enteredLon)
{
    //"fifo like" management
    historyOfLastEnteredLocation[historyOfLastEnteredLocationIn] = enteredLocation;
    historyOfLastEnteredLat[historyOfLastEnteredLocationIn] = enteredLat;
    historyOfLastEnteredLon[historyOfLastEnteredLocationIn] = enteredLon;

    if ((historyOfLastEnteredLocationIn+1) >= historyOfLastEnteredLocationDepth)
        historyOfLastEnteredLocationIn=0;
    else
        historyOfLastEnteredLocationIn+=1;

    if   (historyOfLastEnteredLocationOut == historyOfLastEnteredLocationIn)
    { //fifo is full, so remove one entry
        if ((historyOfLastEnteredLocationOut+1) >= historyOfLastEnteredLocationDepth)
            historyOfLastEnteredLocationOut=0;
        else
            historyOfLastEnteredLocationOut+=1;
    }
}

// Give the formated distance
function distance(meter)
{
	if (meter >= 10000) {
		return Math.round(meter/1000)+"km";
	} else {
		return meter+"m";
	}
}

// Give the formated time
function time(seconds)
{
	if (seconds >= 3600) {
		return Math.floor(seconds/3600)+":"+(Math.floor(seconds/60)%60)+":"+(seconds%60);
	} else {
		return Math.floor(seconds/60)+":"+(seconds%60);
	}
}

// Send a dbus message to layer manager
function lm_message(par, func, args)
{
	return par.message("org.genivi.layermanagementservice","/org/genivi/layermanagementservice","org.genivi.layermanagementservice", func, args);
}

// -------------------- NavigationCore dbus messages --------------------

// Send a message to navigationcore (basic)
function navigationcore_message(par, iface, func, args)
{
	return par.message("org.genivi.navigationcore."+iface,"/org/genivi/navigationcore","org.genivi.navigationcore."+iface, func, args);
}

// Create a new session or get the current session
function nav_session(par) {
    if (g_nav_session)
        return g_nav_session;
    g_nav_session=navigationcore_message(par, "Session", "CreateSession", ["string","TestHMI"]).slice(0,2);
    return g_nav_session;
}

// Delete the current session if exists
function nav_session_clear(par)
{
    if (g_nav_session) {
        navigationcore_message(par, "Session", "DeleteSession", [g_nav_session]);
        g_nav_session=null;
    }
}

// Create a new location handle or get the current handle
function loc_handle(par)
{
    if (g_loc_handle)
        return g_loc_handle;
    g_loc_handle=navigationcore_message(par, "LocationInput","CreateLocationInput", nav_session(par)).slice(0,2);
    return g_loc_handle;
}

// Delete the location handle if exists
function loc_handle_clear(par)
{
    if (g_loc_handle) {
        locationinput_message(par, "DeleteLocationInput", []);
        g_loc_handle=null;
    }
}

// Session messages
function navigationcore_session_message(par, func, args)
{
    return navigationcore_message(par, "Session", func, nav_session(par).concat(loc_handle(par),args));
}

function navigationcoreSession_GetVersion(par)
{
    return navigationcore_session_message(par,"GetVersion",[]);
}

// LocationInput messages
function locationinput_message(par, func, args)
{
    return navigationcore_message(par, "LocationInput", func, nav_session(par).concat(loc_handle(par),args));
}

function locationInput_Spell(dbusIf,inputCharacter,maxWindowSize)
{
    locationinput_message(dbusIf,"Spell",["string",inputCharacter,"uint16",maxWindowSize]);
}


function locationInput_RequestListUpdate(dbusIf,offset,maxWindowSize)
{
    locationinput_message(dbusIf,"RequestListUpdate",["uint16",offset,"uint16",maxWindowSize]);
}

function locationInput_SetSelectionCriterion(dbusIf,selectionCriterion)
{
    locationinput_message(dbusIf,"SetSelectionCriterion",["int32",selectionCriterion]);
}

function locationInput_Search(dbusIf,inputString,maxWindowSize)
{
    locationinput_message(dbusIf,"Search",["string",inputString,"uint16",maxWindowSize]);
}

function locationInput_SelectEntry(dbusIf,index)
{
    locationinput_message(dbusIf,"SelectEntry",["uint16",index]);
}

// Create a new routing handle or get the current handle
// NB: the format is [0]uint32:[1]value
function routing_handle(par) {
    if (g_routing_handle)
        return g_routing_handle;
    g_routing_handle=navigationcore_message(par, "Routing","CreateRoute", nav_session(par)).slice(0,2);
    return g_routing_handle;
}

// Delete the routing handle if exists
function routing_handle_clear(par)
{
    if (g_routing_handle) {
        routing_message(par, "DeleteRoute", []);
        g_routing_handle=0;
    }
}

// Send a message to routing with session handle
function routing_message(par, func, args)
{ //session handle sent
    return navigationcore_message(par, "Routing", func, nav_session(par).concat(routing_handle(par),args));
}

// Send a message to routing without session handle
function routing_message_get(par, func, args)
{
    return navigationcore_message(par, "Routing", func, routing_handle(par).concat(args));
}

function routing_message_GetRouteOverviewTimeAndDistance(dbusIf)
{
    var valuesToReturn=[], pref=[];
    pref=pref.concat("int32",NAVIGATIONCORE_TOTAL_TIME,"int32",NAVIGATIONCORE_TOTAL_DISTANCE);
    valuesToReturn = valuesToReturn.concat("array",[pref]);

    return routing_message_get(dbusIf,"GetRouteOverview",valuesToReturn);
}

function routing_message_GetRouteSegments(dbusIf,detailLevel,numberOfSegments,offset)
{
    var routeSegmentType=["int32",NAVIGATIONCORE_DISTANCE,"int32",NAVIGATIONCORE_TIME,"int32",NAVIGATIONCORE_ROAD_NAME];

    return routing_message_get(dbusIf,"GetRouteSegments",["int16",detailLevel,"array",routeSegmentType,"uint32",numberOfSegments,"uint32",offset]);
}

function latlon_to_map(latlon)
{
    return [
        "int32",NAVIGATIONCORE_LATITUDE,"structure",["uint8",0,"variant",["double",latlon['lat']]],
        "int32",NAVIGATIONCORE_LONGITUDE,"structure",["uint8",0,"variant",["double",latlon['lon']]]
    ];
}

function routing_message_SetWaypoints(dbusIf,startFromCurrentPosition,position,destination)
{
    var message=[];
    if(startFromCurrentPosition==false)
    {
        message=message.concat(["boolean",startFromCurrentPosition,"array",["map",position,"map",destination]]);
    }
    else
    {
        message=message.concat(["boolean",startFromCurrentPosition,"array",["map",position]]);
    }
    routing_message(dbusIf,"SetWaypoints",message);
}

function routing_message_CalculateRoute(dbusIf)
{
    routing_message(dbusIf,"CalculateRoute",[]);
}

function routing_message_GetRouteBoundingBox(dbusIf,routeHandle)
{
    var message=[];
    message=message.concat(nav_session(dbusIf));
    return navigationcore_message(dbusIf, "Routing", "GetRouteBoundingBox", message.concat(routeHandle));
}

//----------------Guidance messages----------------
// Send a message to guidance with session handle
function guidance_message_s(par, func, args)
{
    return navigationcore_message(par, "Guidance", func, nav_session(par).concat(args));
}
// Send a message to guidance without session handle
function guidance_message(par, func, args)
{
    return navigationcore_message(par, "Guidance", func, args);
}

function guidance_message_StartGuidance(dbusIf,routeHandle)
{
    guidance_message_s(dbusIf,"StartGuidance",routeHandle);
}

function guidance_message_StopGuidance(dbusIf)
{
    guidance_message_s(dbusIf,"StopGuidance",[]);
}

function guidance_message_GetGuidanceStatus(dbusIf)
{
    return guidance_message(dbusIf,"GetGuidanceStatus",[]);
}

function guidance_message_GetDestinationInformation(dbusIf)
{
    return guidance_message(dbusIf,"GetDestinationInformation",[]);
}

function guidance_message_GetManeuversList(dbusIf,requestedNumberOfManeuvers,maneuverOffset)
{
    return guidance_message(dbusIf,"GetManeuversList",["uint16",requestedNumberOfManeuvers,"uint32",maneuverOffset]);
}

//----------------Map matched messages----------------
// Send a message to mapmatchedposition with session handle
function mapmatch_message_s(par, func, args)
{
    return navigationcore_message(par, "MapMatchedPosition", func, nav_session(par).concat(args));
}
// Send a message to mapmatchedposition without session handle
function mapmatch_message(par, func, args)
{
    return navigationcore_message(par, "MapMatchedPosition", func, args);
}

function mapmatch_message_GetAddress(dbusIf)
{
    var valuesToReturn=["int32",NAVIGATIONCORE_STREET];

    return mapmatch_message(dbusIf,"GetAddress",["array",valuesToReturn]);
}

function mapmatch_message_SetSimulationMode(dbusIf,activate)
{
    mapmatch_message_s(dbusIf,"SetSimulationMode",["boolean",activate]);
}

function mapmatch_message_StartSimulation(dbusIf)
{
    mapmatch_message_s(dbusIf,"StartSimulation",[]);
}

function mapmatch_message_GetSimulationStatus(dbusIf)
{
    return mapmatch_message(dbusIf,"GetSimulationStatus",[]);
}

function mapmatch_message_GetSimulationSpeed(dbusIf)
{
    return mapmatch_message(dbusIf,"GetSimulationSpeed",[]);
}

function mapmatch_message_GetPosition(dbusIf)
{
    var valuesToReturn=["int32",NAVIGATIONCORE_SPEED,"int32",NAVIGATIONCORE_LATITUDE,"int32",NAVIGATIONCORE_LONGITUDE];

    return mapmatch_message(dbusIf,"GetPosition",["array",valuesToReturn]);
}

//----------------MapViewerControl messages----------------
// Send a message to mapviewer (basic)
function map_message(par, iface, func, args)
{
	return par.message("org.genivi.mapviewer."+iface,"/org/genivi/mapviewer","org.genivi.mapviewer."+iface, func, args);
}

// Create a new session or get the current session
// NB: the format is [0]uint32:[1]value
function map_session(par) {
	if (g_map_session)
		return g_map_session;
	g_map_session=map_message(par, "Session", "CreateSession", ["string","TestHMI"]).slice(0,2);
	return g_map_session;
}

// Delete the current session if exists
function map_session_clear(par)
{
	if (g_map_session) {
		map_message(par, "Session", "DeleteSession", [g_map_session]);
		g_map_session=null;
	}
}

// Create a new map handle or get the current handle
// NB: the format is [0]uint32:[1]value
function map_handle(par,w,h,type)
{
	if (g_map_handle)
		return g_map_handle;
    g_map_handle=map_message(par, "MapViewerControl","CreateMapViewInstance", map_session(par).concat(["structure",["uint16",w,"uint16",h],"int32",type])).slice(0,2);
	return g_map_handle;
}

// Delete the map handle if exists
function map_handle_clear(par)
{
    if (g_map_handle) {
        mapviewercontrol_message(par, "ReleaseMapViewInstance", []);
        g_map_handle=null;
    }
}

// Send a message to map viewer control with session handle
function mapviewercontrol_message(par, func, args)
{
	return map_message(par, "MapViewerControl", func, map_session(par).concat(g_map_handle,args));
}

function mapviewercontrol_message_GetMapViewScale(dbusIf)
{
    return mapviewercontrol_message(dbusIf,"GetMapViewScale", []);
}

function mapviewercontrol_message_GetMapViewPerspective(dbusIf)
{
    return mapviewercontrol_message(dbusIf,"GetMapViewPerspective", []);
}

function mapviewercontrol_message_GetDisplayedRoutes(dbusIf)
{
    return mapviewercontrol_message(dbusIf,"GetDisplayedRoutes", []);
}

function mapviewercontrol_message_GetMapViewTheme(dbusIf)
{
    return mapviewercontrol_message(dbusIf,"GetMapViewTheme", []);
}

function mapviewercontrol_message_SetMapViewScaleByDelta(dbusIf,scaleDelta)
{
    mapviewercontrol_message(dbusIf,"SetMapViewScaleByDelta", ["int16",scaleDelta]);
}

function mapviewercontrol_message_SetMapViewTheme(dbusIf,mapViewTheme)
{
    mapviewercontrol_message(dbusIf,"SetMapViewTheme", ["int32",mapViewTheme]);
}

function mapviewercontrol_message_SetMapViewPerspective(dbusIf,perspective)
{
    mapviewercontrol_message(dbusIf,"SetMapViewPerspective", ["int32",perspective]);
}

function mapviewercontrol_message_SetFollowCarMode(dbusIf,followCarMode)
{
    mapviewercontrol_message(dbusIf,"SetFollowCarMode", ["boolean",followCarMode]);
}

function mapviewercontrol_message_DisplayRoute(dbusIf,routeHandle,highlighted)
{
    var args=[];
    args=args.concat(routeHandle);
    mapviewercontrol_message(dbusIf,"DisplayRoute", args.concat("boolean",highlighted));
}

function mapviewercontrol_message_SetTargetPoint(dbusIf,latitude,longitude,altitude)
{
    mapviewercontrol_message(dbusIf, "SetTargetPoint", ["structure",["double",latitude,"double",longitude,"double",altitude]]);
}

function mapviewercontrol_message_SetMapViewBoundingBox(dbusIf,boundingBox)
{
    mapviewercontrol_message(dbusIf,"SetMapViewBoundingBox", boundingBox);
}


// Create a new map handle or get the current handle
// NB: the format is [0]uint32:[1]value
function map_handle2(par,w,h,type)
{
	if (g_map_handle2)
		return g_map_handle2;
	g_map_handle2=map_message(par, "MapViewerControl","CreateMapViewInstance", map_session(par).concat(["structure",["uint16",w,"uint16",h],"uint16",type])).slice(0,2);
	return g_map_handle2;
}

// Delete the map handle if exists
function map_handle_clear2(par)
{
    if (g_map_handle2) {
        mapviewercontrol_message2(par, "ReleaseMapViewInstance", []);
        g_map_handle2=null;
    }
}

// Send a message to map viewer control with session handle on handle 2
function mapviewercontrol_message2(par, func, args)
{
	return map_message(par, "MapViewerControl", func, map_session(par).concat(g_map_handle2,args));
}

function mapviewercontrol_message2_SetMapViewTheme(dbusIf,mapViewTheme)
{
    mapviewercontrol_message2(dbusIf,"SetMapViewTheme", ["uint16",mapViewTheme]);
}

function mapviewercontrol_message2_SetMapViewBoundingBox(dbusIf,boundingBox)
{
    mapviewercontrol_message2(dbusIf,"SetMapViewBoundingBox", boundingBox);
}

function mapviewercontrol_message2_DisplayRoute(dbusIf,routeHandle,highlighted)
{
    var args=[];
    args=args.concat(routeHandle);
    mapviewercontrol_message2(dbusIf,"DisplayRoute", args.concat("boolean",highlighted));
}

// -------------------- POISearch dbus messages --------------------

// Send a message to poiservice (basic)
function poi_message(par, iface, func, args)
{
	return par.message("org.genivi.poiservice."+iface,"/org/genivi/poiservice/"+iface,"org.genivi.poiservice."+iface, func, args);
}

// Send a message to poisearch with session handle
function poisearch_message(par, func, args)
{ //session handle sent
    return poi_message(par, "POISearch", func, poisearch_handle(par).concat(args));
}

// Send a message to poisearch without session handle
function poisearch_message_get(par, func, args)
{
    return poi_message(par, "POISearch", func, args);
}

// Create a new poisearch handle or get the current handle
// NB: the format is [0]uint32:[1]value
function poisearch_handle(par) {
    if (g_poisearch_handle)
        return g_poisearch_handle;
    g_poisearch_handle=poisearch_message_get(par, "CreatePoiSearchHandle", []);
    return g_poisearch_handle;
}

// Delete the poisearch handle if exists
function poisearch_handle_clear(par)
{
    if (g_poisearch_handle) {
        poisearch_message(par, "DeletePoiSearchHandle", []);
        g_poisearch_handle=null;
    }
}

// Send a message to demonstrator (basic)
function demonstrator_message(par, iface, func, args)
{
	return par.message("org.genivi.demonstrator."+iface,"/org/genivi/demonstrator/"+iface,"org.genivi.demonstrator."+iface, func, args);
}

// Send a message to tripcomputer (basic)
function tripcomputer_message(par, func, args)
{
	return demonstrator_message(par, "TripComputer", func, args);
}

// Send a message to fuel stop advisor (basic)
function fuel_stop_advisor_message(par, func, args)
{
	return demonstrator_message(par, "FuelStopAdvisor", func, args);
}

function fuel_stop_advisor_ReleaseRouteHandle(dbusIf,routeHandle)
{
    fuel_stop_advisor_message(dbusIf,"ReleaseRouteHandle",routeHandle);
}

function fuel_stop_advisor_SetRouteHandle(dbusIf,routeHandle)
{
    fuel_stop_advisor_message(dbusIf,"SetRouteHandle",routeHandle);
}

function fuel_stop_advisor_SetFuelAdvisorSettings(dbusIf,advisorMode,distanceThreshold)
{
    fuel_stop_advisor_message(dbusIf,"SetFuelAdvisorSettings",["boolean",advisorMode,"uint8",distanceThreshold]);
}

function setlang(lang)
{
	g_lang=lang;
    translations = new Array;
    Qt.include("translations/"+lang+".js");
}

function gettext(arg)
{
    if (!translations[arg]) {
        if (g_lang) {
            console.log("Translation for '" + arg + "' missing for " + g_lang);
        }
        return arg;
    } else {
        return translations[arg];
    }
}
