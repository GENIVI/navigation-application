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

Qt.include("../../../../bin/hmi/qml/constants.js");
var Test;
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

var entryback;
var entrydest;
var entrycriterion;
var entryselectedentry;

var Maneuver = new Object;
Maneuver[NAVIGATIONCORE_INVALID]="INVALID";
Maneuver[NAVIGATIONCORE_CRUISE]="CRUISE";
Maneuver[NAVIGATIONCORE_MANEUVER_APPEARED]="MANEUVER_APPEARED";
Maneuver[NAVIGATIONCORE_PRE_ADVICE]="PRE_ADVICE";
Maneuver[NAVIGATIONCORE_ADVICE]="ADVICE";
Maneuver[NAVIGATIONCORE_PASSED]="PASSED";


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

//the default data below will be managed by the persistency component in the future
address[NAVIGATIONCORE_COUNTRY]="Switzerland";
address[NAVIGATIONCORE_CITY]="Genève";
address[NAVIGATIONCORE_STREET]="Rue de l'Avenir";
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
function nav_message(par, iface, func, args)
{
	return par.message("org.genivi.navigationcore."+iface,"/org/genivi/navigationcore","org.genivi.navigationcore."+iface, func, args);
}

// Create a new session or get the current session
function nav_session(par) {
    if (g_nav_session)
        return g_nav_session;
    g_nav_session=nav_message(par, "Session", "CreateSession", ["string","TestHMI"]).slice(0,2);
    return g_nav_session;
}

// Delete the current session if exists
function nav_session_clear(par)
{
    if (g_nav_session) {
        nav_message(par, "Session", "DeleteSession", [g_nav_session]);
        g_nav_session=null;
    }
}

// Create a new location handle or get the current handle
function loc_handle(par)
{
    if (g_loc_handle)
        return g_loc_handle;
    g_loc_handle=nav_message(par, "LocationInput","CreateLocationInput", nav_session(par)).slice(0,2);
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

// Send a message to LocationInput
function locationinput_message(par, func, args)
{
    return nav_message(par, "LocationInput", func, nav_session(par).concat(loc_handle(par),args));
}

// Create a new routing handle or get the current handle
function routing_handle(par) {
    if (g_routing_handle)
        return g_routing_handle;
    g_routing_handle=nav_message(par, "Routing","CreateRoute", nav_session(par)).slice(0,2);
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
    return nav_message(par, "Routing", func, nav_session(par).concat(routing_handle(par),args));
}

// Send a message to routing without session handle
function routing_message_get(par, func, args)
{
    return nav_message(par, "Routing", func, routing_handle(par).concat(args));
}

// Send a message to guidance with session handle
function guidance_message(par, func, args)
{
    return nav_message(par, "Guidance", func, nav_session(par).concat(args));
}

// Send a message to guidance without session handle
function guidance_message_get(par, func, args)
{
    return nav_message(par, "Guidance", func, args);
}

// Send a message to mapmatchedposition with session handle
function mapmatch_message(par, func, args)
{
    return nav_message(par, "MapMatchedPosition", func, nav_session(par).concat(args));
}

// Send a message to mapmatchedposition without session handle
function mapmatch_message_get(par, func, args)
{
    return nav_message(par, "MapMatchedPosition", func, args);
}


// -------------------- MapViewerControl dbus messages --------------------

// Send a message to mapviewer (basic)
function map_message(par, iface, func, args)
{
	return par.message("org.genivi.mapviewer."+iface,"/org/genivi/mapviewer","org.genivi.mapviewer."+iface, func, args);
}

// Create a new session or get the current session
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
function map_handle(par,w,h,type)
{
	if (g_map_handle)
		return g_map_handle;
	g_map_handle=map_message(par, "MapViewerControl","CreateMapViewInstance", map_session(par).concat(["structure",["uint16",w,"uint16",h],"uint16",type])).slice(0,2);
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

// Create a new map handle or get the current handle
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

// Send a message to map viewer control with session handle
function mapviewercontrol_message2(par, func, args)
{
	return map_message(par, "MapViewerControl", func, map_session(par).concat(g_map_handle2,args));
}

// Send a message to poiservice (basic)
function poi_message(par, iface, func, args)
{
	return par.message("org.genivi.poiservice."+iface,"/org/genivi/poiservice/"+iface,"org.genivi.poiservice."+iface, func, args);
}

// Create a new poisearch handle or get the current handle
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
