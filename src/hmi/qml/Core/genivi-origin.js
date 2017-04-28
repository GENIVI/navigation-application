/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2016, PCA Peugeot Citroen
*
* \file genivi-origin.js
*
* \brief This file is part of the navigation hmi. It defines basic functions used by the QML files, for the former version of the FSA.
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
var g_nav_session=["uint32",0];
var g_locationinput_handle=["uint32",0];
var g_routing_handle=["uint32",0];
var g_mapviewer_session=["uint32",0];
var g_mapviewer_handle=["uint32",0];
var g_mapviewer_handle2=["uint32",0];
var g_poisearch_handle=["uint32",0];
var g_language,g_country,g_script;

var data=new Array;
data['destination']=new Array; //the destination
data['position']=new Array; //a position
data['current_position']=new Array; //the current position
data['default_position']=new Array; //the default position used for the showrooom

var poi_data=new Array;
var poi_id=null;
var category_id;

var categoriesIdNameList;

var translations=new Array;

var simulationMode=false;// simulation mode off by default
var showroom=false; //showroom off by default
var autoguidance=false; //no automatic display route on guidance by default

var guidance_activated=false;
var route_calculated=false;
var reroute_requested=false;
var location_input_activated=true;

function setRouteCalculated(arg)
{
    route_calculated=arg;
    if(verbose===true){
        console.log("Routing: ",route_calculated);
    }
}

function setGuidanceActivated(arg)
{
    guidance_activated=arg;
    if(verbose===true){
        console.log(" Guidance: ",guidance_activated);
    }
}

function setLocationInputActivated(arg)
{
    location_input_activated=arg;
    if(verbose===true){
        console.log("Location input: ",location_input_activated);
    }
}

function setRerouteRequested(arg)
{
    reroute_requested=arg;
    if(verbose===true){
        console.log("Rerouting: ",reroute_requested);
    }
}

var scaleList;
var minZoomId;
var maxZoomId;

var entryback = new Array;
var entrybackheapsize=0;
entryback[entrybackheapsize]="";
var entrydest=null;
var entrycriterion;
var entryselectedentry;

var roadPreferenceList=new Object;
roadPreferenceList[NAVIGATIONCORE_FERRY]=NAVIGATIONCORE_AVOID;
roadPreferenceList[NAVIGATIONCORE_TOLL_ROADS]=NAVIGATIONCORE_AVOID;
roadPreferenceList[NAVIGATIONCORE_HIGHWAYS_MOTORWAYS]=NAVIGATIONCORE_AVOID;
var conditionPreferenceList=new Object;
conditionPreferenceList[NAVIGATIONCORE_TRAFFIC_REALTIME]=NAVIGATIONCORE_AVOID;

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
ManeuverDirection[NAVIGATIONCORE_STRAIGHT]="STRAIGHT";
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

var verbose=false; //no log sent to stdout by default
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
var maxResultListSize=50; //max size of elements to return as a result
var fuelCategoryId; //unique id of fuel category
var zoom_guidance=2; //zoom level when a guidance starts

data['display_on_map']='show_current_position'; //display current position of the vehicle on the map

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

function hookContext()
{
    if(verbose===true){
        console.log("Routing: ",route_calculated," Guidance: ",guidance_activated," Simulation: ",simulationMode);
    }
}

function setVerbose()
{
    verbose=true;
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

// Keyboard parameters
var kbdColumns; //number of columns per line
var kbdColumnRatio; //size of column spacing (ratio)
var kbdLines; //number of lines
var kbdLineRatio; //size of line spacing (ratio)
var kbdFirstLayout;
var kbdSecondLayout;
var keyboardLayout;
var germanLayout={
    'ABC':['A','B','C','D','E','F','G','H',
           'I','J','K','L','M','N','O','P',
           'Q','R','S','T','U','V','W','X',
           'Y','Z','␣','','','123','ÄÖÜ','←',
        ],
    'ÄÖÜ':['Ä','Ö','Ü','ß','','','','',
           '','','','','','','','',
           '','','','','','','','',
           '','','','','','123','ABC','←',
        ],
    '123':['0','1','2','3','4','5','6','7',
           '8','9','-','.',',','','','',
           '','','','','','','','',
           '','','','','','ABC','ÄÖÜ','←',
        ],
};
var frenchLayout={
    'ABC':['A','B','C','D','E','F','G','H',
           'I','J','K','L','M','N','O','P',
           'Q','R','S','T','U','V','W','X',
           'Y','Z','␣','','','123','','←',
        ],
    '123':['0','1','2','3','4','5','6','7',
           '8','9','-','.',',','','','',
           '','','','','','','','',
           '','','','','','ABC','','←',
        ],
};
var englishLayout={
    'ABC':['A','B','C','D','E','F','G','H',
           'I','J','K','L','M','N','O','P',
           'Q','R','S','T','U','V','W','X',
           'Y','Z','␣','','','123','','←',
        ],
    '123':['0','1','2','3','4','5','6','7',
           '8','9','-','.',',','','','',
           '','','','','','','','',
           '','','','','','ABC','','←',
        ],
};
var japaneseLayout={
    'かな':['あ','か','さ','た','な','は','ま','や','ら','わ',
        　　'い','き','し','ち','に','ひ','み','','り','を',
        　　'う','く','す','つ','ぬ','ふ','む','ゆ','る','ん',
        　　'え','け','せ','て','ね','へ','め','','れ','”',
        　　'お','こ','そ','と','の','ほ','も','よ','ろ','°',
        　　'カナ','ABC','123','','','','','','','←',
        ],
    'カナ':['ア','カ','サ','タ','ナ','ハ','マ','ヤ','ラ','ワ',
        　　'イ','キ','シ','チ','ニ','ヒ','ミ','','リ','ヲ',
        　　'ウ','ク','ス','ツ','ヌ','フ','ム','ユ','ル','ン',
        　　'エ','ケ','セ','テ','ネ','ヘ','メ','','レ','”',
        　　'オ','コ','ソ','ト','ノ','ホ','モ','ヨ','ロ','°',
        　　'かな','ABC','123','','','','','','ー','←',
        ],
    'ABC':['A','Z','E','R','T','Y','U','I','O','P',
        　　'Q','S','D','F','G','H','J','K','L','M',
        　　'W','X','C','V','B','N','','','','',
        　　'','','','','','','','','','',
        　　'','','','','','','','','','',
        　　'かな','','123','','␣','','','','','←',
        ],
    '123':['0','1','2','3','4','5','6','7','8','9',
        　　'','','','','','','','','','',
        　　'','','','','','','','','','',
        　　'','','','','','','','','','',
        　　'','','','','','','','','','',
        　　'かな','ABC','','','','','','','','←',
        ],
};

// Language and text
function setlang(language,country,script)
{
    g_language=language;
    g_country=country;
    g_script=script;
    translations = new Array;
    Qt.include("../../translations/"+g_language + "_" + g_country+".js");
    if(g_language==="eng"){
        keyboardLayout=englishLayout;
        kbdFirstLayout="ABC";
        kbdSecondLayout="123";
        kbdColumns=8; //number of rows per line
        kbdColumnRatio=4; //size of row spacing (ratio)
        kbdLines=4; //number of lines
        kbdLineRatio=4; //size of line spacing (ratio)
    }else{
        if(g_language==="fra"){
            keyboardLayout=frenchLayout;
            kbdFirstLayout="ABC";
            kbdSecondLayout="123";
            kbdColumns=8; //number of rows per line
            kbdColumnRatio=4; //size of row spacing (ratio)
            kbdLines=4; //number of lines
            kbdLineRatio=4; //size of line spacing (ratio)
        }else{
            if(g_language==="jpn"){
                keyboardLayout=japaneseLayout;
                kbdFirstLayout="かな";
                kbdSecondLayout="カナ";
                kbdColumns=10; //number of rows per line
                kbdColumnRatio=4; //size of row spacing (ratio)
                kbdLines=6; //number of lines
                kbdLineRatio=4; //size of line spacing (ratio)
            }else{
                if(g_language==="deu"){
                    keyboardLayout=germanLayout;
                    kbdFirstLayout="ABC";
                    kbdSecondLayout="123";
                    kbdColumns=8; //number of rows per line
                    kbdColumnRatio=4; //size of row spacing (ratio)
                    kbdLines=4; //number of lines
                    kbdLineRatio=4; //size of line spacing (ratio)
                }else{
                    //default
                    keyboardLayout=germanLayout;
                    kbdColumns=8; //number of rows per line
                    kbdColumnRatio=4; //size of row spacing (ratio)
                    kbdLines=4; //number of lines
                    kbdLineRatio=4; //size of line spacing (ratio)
                }
            }
        }
    }
}
// Default position (for showroom mode)
function setDefaultPosition(lat,lon,alt)
{
    data['default_position']['lat']= lat;
    data['default_position']['lon']= lon;
    data['default_position']['alt']= alt;
}

// Default address
function setDefaultAddress(country,city,street,number)
{
    address[NAVIGATIONCORE_COUNTRY]=country;
    address[NAVIGATIONCORE_CITY]=city;
    address[NAVIGATIONCORE_STREET]=street;
    address[NAVIGATIONCORE_HOUSENUMBER]=number;
}

function gettext(arg)
{
    if (!translations[arg]) {
        if (g_language) {
            console.log("Translation for '" + arg + "' missing for " + g_language);
        }
        return arg;
    } else {
        return translations[arg];
    }
}

//----------------- Management of the DBus messages -----------------

function hookMethod(arg)
{
    if(verbose===true){
        console.log("Method: ",arg);
    }
}

// Send a dbus message to layer manager
function lm_message(par, func, args)
{
    //    console.log("Method: ",func);
    return par.message("org.genivi.layermanagementservice","/org/genivi/layermanagementservice","org.genivi.layermanagementservice", func, args);
}

// Send a message to navigationcore (basic)
function navigationcore_message(par, iface, func, args)
{
    hookMethod(func);
    return par.message("org.genivi.navigation.navigationcore."+iface,"/org/genivi/navigationcore","org.genivi.navigation.navigationcore."+iface, func, args);
}

// Send a message to mapviewer (basic)
function mapviewer_message(par, iface, func, args)
{
    hookMethod(func);
    return par.message("org.genivi.navigation.mapviewer."+iface,"/org/genivi/mapviewer","org.genivi.navigation.mapviewer."+iface, func, args);
}

// Send a message to poiservice (basic)
function poi_message(par, iface, func, args)
{
    hookMethod(func);
    return par.message("org.genivi.navigation.poiservice."+iface,"/org/genivi/poiservice/"+iface,"org.genivi.navigation.poiservice."+iface, func, args);
}

// Send a message to demonstrator (basic)
function demonstrator_message(par, iface, func, args)
{
    hookMethod(func);
    return par.message("org.genivi.demonstrator."+iface,"/org/genivi/demonstrator/"+iface,"org.genivi.demonstrator."+iface, func, args);
}

//----------------- DBus signals -----------------
function hookSignal(arg)
{
    if(verbose===true){
        console.log("Signal: ",arg);
    }
}

function connect_simulationStatusChangedSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.MapMatchedPosition","SimulationStatusChanged",menu,"simulationStatusChanged");
}

function connect_simulationSpeedChangedSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.MapMatchedPosition","SimulationSpeedChanged",menu,"simulationSpeedChanged");
}

function connect_searchStatusSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.LocationInput","SearchStatus",menu,"searchStatus");
}

function connect_searchResultListSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.LocationInput","SearchResultList",menu,"searchResultList");
}

function connect_spellResultSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.LocationInput","SpellResult",menu,"spellResult");
}

function connect_guidanceStatusChangedSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.Guidance","GuidanceStatusChanged",menu,"guidanceStatusChanged");
}

function connect_guidanceWaypointReachedSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.Guidance","WaypointReached",menu,"guidanceWaypointReached");
}

function connect_guidanceManeuverChangedSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.Guidance","ManeuverChanged",menu,"guidanceManeuverChanged");
}

function connect_guidancePositionOnRouteChangedSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.Guidance","PositionOnRouteChanged",menu,"guidancePositionOnRouteChanged");
}

function connect_mapmatchedpositionPositionUpdateSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.MapMatchedPosition","PositionUpdate",menu,"mapmatchedpositionPositionUpdate");
}

function connect_mapmatchedpositionAddressUpdateSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.MapMatchedPosition","AddressUpdate",menu,"mapmatchedpositionAddressUpdate");
}

function connect_routeCalculationSuccessfulSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.Routing","RouteCalculationSuccessful",menu,"routeCalculationSuccessful");
}

function connect_routeCalculationFailedSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.Routing","RouteCalculationFailed",menu,"routeCalculationFailed");
}

function connect_routeCalculationProgressUpdateSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.Routing","RouteCalculationProgressUpdate",menu,"routeCalculationProgressUpdate");
}

function connect_currentSelectionCriterionSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.LocationInput","CurrentSelectionCriterion",menu,"currentSelectionCriterion");
}

function connect_contentUpdatedSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.LocationInput","ContentUpdated",menu,"contentUpdated");
}

function connect_configurationChangedSignal(interface,menu)
{
    return interface.connect("","/org/genivi/navigationcore","org.genivi.navigation.navigationcore.Configuration","ConfigurationChanged",menu,"configurationChanged");
}

function connect_tripDataUpdatedSignal(interface,menu)
{
    return interface.connect("","/org/genivi/demonstrator/FuelStopAdvisor","org.genivi.demonstrator.FuelStopAdvisor","TripDataUpdated",menu,"tripDataUpdated");
}

function connect_fuelStopAdvisorWarningSignal(interface,menu)
{
    return interface.connect("","/org/genivi/demonstrator/FuelStopAdvisor","org.genivi.demonstrator.FuelStopAdvisor","FuelStopAdvisorWarning",menu,"fuelStopAdvisorWarning");
}

function connect_mapViewScaleChangedSignal(interface,menu)
{
    return interface.connect("","/org/genivi/mapviewer","org.genivi.navigation.mapviewer.MapViewerControl","MapViewScaleChanged",menu,"mapViewScaleChanged");
}

//----------------- NavigationCore dbus messages -----------------

//----------------- Navigation core Session messages -----------------

function navigationcore_session_message(par, func, args)
{
    return navigationcore_message(par, "Session", func, args);
}

// Create a new session or get the current session
function navigationcore_session(par) {
    if (!g_nav_session[1])
    {
        var res=navigationcore_session_message(par,"CreateSession", ["string","TestHMI"]);
        g_nav_session[1]=res[3];
    }
    return g_nav_session;
}

// Delete the current session if exists
function navigationcore_session_clear(par)
{
    if (g_nav_session[1]) {
        var res=navigationcore_session_message(par,"DeleteSession", g_nav_session);
        g_nav_session[1]=0;
    }
}

function navigationcore_session_GetVersion(par)
{
    return navigationcore_session_message(par,"GetVersion",[]);
}

//----------------- Navigation core Configuration messages -----------------

function navigationcore_configuration_message(par, func, args)
{
    return navigationcore_message(par, "Configuration", func,args);
}

function navigationcore_configuration_GetSupportedLocales(dbusIf)
{
    return navigationcore_configuration_message(dbusIf,"GetSupportedLocales",[]);
}

function navigationcore_configuration_GetLocale(dbusIf)
{
    return navigationcore_configuration_message(dbusIf,"GetLocale",[]);
}

function navigationcore_configuration_SetLocale(dbusIf,language,country,script)
{
    navigationcore_configuration_message(dbusIf,"SetLocale",["string",language,"string",country,"string",script]);
}

function navigationcore_configuration_GetUnitsOfMeasurement(dbusIf)
{
    return navigationcore_configuration_message(dbusIf,"GetUnitsOfMeasurement",[]);
}

function navigationcore_configuration_SetUnitsOfMeasurementLength(dbusIf,unit)
{
    navigationcore_configuration_message(dbusIf,"SetUnitsOfMeasurement",["map",["int32",NAVIGATIONCORE_LENGTH,"int32",unit]]);
}

//----------------- LocationInput messages -----------------

// Create a new location handle or get the current handle
function locationinput_handle(par)
{
    if (!g_locationinput_handle[1])
    {
        var res=navigationcore_message(par, "LocationInput","CreateLocationInput", navigationcore_session(par));
        g_locationinput_handle[1]=res[3];
    }
    return g_locationinput_handle;
}

function locationinput_message(par, func, args)
{
    return navigationcore_message(par, "LocationInput", func, navigationcore_session(par).concat(locationinput_handle(par),args));
}

function locationinput_Spell(dbusIf,inputCharacter,maxWindowSize)
{
    locationinput_message(dbusIf,"Spell",["string",inputCharacter,"uint16",maxWindowSize]);
}

function locationinput_RequestListUpdate(dbusIf,offset,maxWindowSize)
{
    locationinput_message(dbusIf,"RequestListUpdate",["uint16",offset,"uint16",maxWindowSize]);
}

function locationinput_SetSelectionCriterion(dbusIf,selectionCriterion)
{
    locationinput_message(dbusIf,"SetSelectionCriterion",["int32",selectionCriterion]);
}

function locationinput_Search(dbusIf,inputString,maxWindowSize)
{
    locationinput_message(dbusIf,"Search",["string",inputString,"uint16",maxWindowSize]);
}

function locationinput_SelectEntry(dbusIf,index)
{
    locationinput_message(dbusIf,"SelectEntry",["uint16",index]);
}

function locationinput_handle_clear(par)
{
    if (g_locationinput_handle[1]) {
        var res=locationinput_message(par, "DeleteLocationInput", []);
        g_locationinput_handle[1]=0;
    }
}

//----------------- Routing messages -----------------

// Send a message to routing with session handle and route handle
function routing_message(par, func, args)
{ //session handle sent
    return navigationcore_message(par, "Routing", func, navigationcore_session(par).concat(routing_handle(par),args));
}

// Send a message to routing with route handle
function routing_get(par, func, args)
{
    return navigationcore_message(par, "Routing", func, routing_handle(par).concat(args));
}

// Send a message to routing
function routing(par, func, args)
{
    return navigationcore_message(par, "Routing", func, args);
}

// Create a new routing handle or get the current handle
function routing_handle(par) {
    if (!g_routing_handle[1])
    {
        var res=navigationcore_message(par, "Routing","CreateRoute", navigationcore_session(par));
        g_routing_handle[1]=res[3];
    }
    return g_routing_handle;
}

// Delete the routing handle if exists
function routing_handle_clear(par)
{
    if (g_routing_handle[1]) {
        var res=routing_message(par, "DeleteRoute", []);
        g_routing_handle[1]=0;
    }
}

function routing_GetRouteOverviewTimeAndDistance(dbusIf)
{
    var valuesToReturn=[], pref=[];
    pref=pref.concat("int32",NAVIGATIONCORE_TOTAL_TIME,"int32",NAVIGATIONCORE_TOTAL_DISTANCE);
    valuesToReturn = valuesToReturn.concat("array",[pref]);

    return routing_get(dbusIf,"GetRouteOverview",valuesToReturn);
}

function routing_GetCostModel(dbusIf)
{
    return routing_get(dbusIf,"GetCostModel",[]);
}

function routing_SetCostModel(dbusIf,costModel)
{
    var res=routing_message(dbusIf,"SetCostModel",["int32",costModel]);
}

function routing_GetSupportedCostModels(dbusIf)
{
    return routing(dbusIf,"GetSupportedCostModels",[]);
}

function routing_GetSupportedRoutePreferences(dbusIf)
{
    return routing(dbusIf,"GetSupportedRoutePreferences",[]);
}

function routing_GetRoutePreferences(dbusIf,countryCode)
{
    return routing_get(dbusIf,"GetRoutePreferences",["string",countryCode]);
}

function routing_SetRoutePreferences(dbusIf,countryCode)
{
    var roadMessage=["array",["structure",["int32",roadPreferenceList[NAVIGATIONCORE_FERRY],"int32",NAVIGATIONCORE_FERRY],"structure",["int32",roadPreferenceList[NAVIGATIONCORE_TOLL_ROADS],"int32",NAVIGATIONCORE_TOLL_ROADS],"structure",["int32",roadPreferenceList[NAVIGATIONCORE_HIGHWAYS_MOTORWAYS],"int32",NAVIGATIONCORE_HIGHWAYS_MOTORWAYS]]];
    var conditionMessage=["array",["structure",["int32",conditionPreferenceList[NAVIGATIONCORE_TRAFFIC_REALTIME],"int32",NAVIGATIONCORE_TRAFFIC_REALTIME]]];
    var message=["string",countryCode];
    message=message.concat(roadMessage.concat(conditionMessage));
    var res=routing_message(dbusIf,"SetRoutePreferences",message);
}

function routing_GetRouteSegments(dbusIf,detailLevel,numberOfSegments,offset)
{
    var routeSegmentType=["int32",NAVIGATIONCORE_DISTANCE,"int32",NAVIGATIONCORE_TIME,"int32",NAVIGATIONCORE_ROAD_NAME];

    return routing_get(dbusIf,"GetRouteSegments",["int16",detailLevel,"array",routeSegmentType,"uint32",numberOfSegments,"uint32",offset]);
}

function latlon_to_map(latlon)
{
    return [
        "int32",NAVIGATIONCORE_LATITUDE,"structure",["uint8",3,"variant",["double",latlon['lat']]],
        "int32",NAVIGATIONCORE_LONGITUDE,"structure",["uint8",3,"variant",["double",latlon['lon']]]
    ];
}

function routing_SetWaypoints(dbusIf,startFromCurrentPosition,position,destination)
{
    var message=[];
    if(startFromCurrentPosition==false)
    {
        message=message.concat(["boolean",startFromCurrentPosition,"array",["map",position,"map",destination]]);
    }
    else
    {
        message=message.concat(["boolean",startFromCurrentPosition,"array",["map",destination]]);
    }
    var res=routing_message(dbusIf,"SetWaypoints",message);
}

function routing_CalculateRoute(dbusIf)
{
    var res=routing_message(dbusIf,"CalculateRoute",[]);
}

function routing_GetRouteBoundingBox(dbusIf,routeHandle)
{
    var message=[];
    return navigationcore_message(dbusIf, "Routing", "GetRouteBoundingBox", message.concat(routeHandle));
}

//----------------- Guidance messages -----------------

// Send a message to guidance with session handle
function guidance_s(par, func, args)
{
    return navigationcore_message(par, "Guidance", func, navigationcore_session(par).concat(args));
}
// Send a message to guidance without session handle
function guidance_get(par, func, args)
{
    return navigationcore_message(par, "Guidance", func, args);
}

function guidance_StartGuidance(dbusIf,routeHandle)
{
    guidance_s(dbusIf,"StartGuidance",routeHandle);
}

function guidance_StopGuidance(dbusIf)
{
    guidance_s(dbusIf,"StopGuidance",[]);
}

function guidance_GetGuidanceStatus(dbusIf)
{
    return guidance_get(dbusIf,"GetGuidanceStatus",[]);
}

function guidance_GetDestinationInformation(dbusIf)
{
    return guidance_get(dbusIf,"GetDestinationInformation",[]);
}

function guidance_GetManeuversList(dbusIf,requestedNumberOfManeuvers,maneuverOffset)
{
    return guidance_get(dbusIf,"GetManeuversList",["uint16",requestedNumberOfManeuvers,"uint32",maneuverOffset]);
}

//---------------- Map matched position messages ----------------

// Send a message to mapmatchedposition with session handle
function mapmatchedposition_message(par, func, args)
{
    return navigationcore_message(par, "MapMatchedPosition", func, navigationcore_session(par).concat(args));
}

// Send a message to mapmatchedposition without session handle
function mapmatchedposition_get(par, func, args)
{
    return navigationcore_message(par, "MapMatchedPosition", func, args);
}

function mapmatchedposition_GetCurrentAddress(dbusIf)
{
    var valuesToReturn=["int32",NAVIGATIONCORE_STREET];

    return mapmatchedposition_get(dbusIf,"GetCurrentAddress",["array",valuesToReturn]);
}

function mapmatchedposition_SetSimulationMode(dbusIf,activate)
{
    mapmatchedposition_message(dbusIf,"SetSimulationMode",["boolean",activate]);
}

function mapmatchedposition_StartSimulation(dbusIf)
{
    mapmatchedposition_message(dbusIf,"StartSimulation",[]);
}

function mapmatchedposition_PauseSimulation(dbusIf)
{
    mapmatchedposition_message(dbusIf,"PauseSimulation",[]);
}

function mapmatchedposition_GetSimulationStatus(dbusIf)
{
    return mapmatchedposition_get(dbusIf,"GetSimulationStatus",[]);
}

function mapmatchedposition_GetSimulationSpeed(dbusIf)
{
    return mapmatchedposition_get(dbusIf,"GetSimulationSpeed",[]);
}

function mapmatchedposition_SetSimulationSpeed(dbusIf,speedFactor)
{
    mapmatchedposition_message(dbusIf,"SetSimulationSpeed",["uint8",speedFactor]);
}

function mapmatchedposition_GetPosition(dbusIf)
{
    var valuesToReturn=["int32",NAVIGATIONCORE_SPEED,"int32",NAVIGATIONCORE_LATITUDE,"int32",NAVIGATIONCORE_LONGITUDE];

    return mapmatchedposition_get(dbusIf,"GetPosition",["array",valuesToReturn]);
}

//---------------- MapViewer messages (handle 1) ----------------

// Create a new session or get the current session
function mapviewer_session(par) {
    if (!g_mapviewer_session[1])
    {
        var res=mapviewer_message(par, "Session", "CreateSession", ["string","TestHMI"]);
        g_mapviewer_session[1]=res[3];
    }
    return g_mapviewer_session;
}

// Delete the current session if exists
function mapviewer_session_clear(par)
{
    if (g_mapviewer_session[1]) {
        var res=mapviewer_message(par, "Session", "DeleteSession", [g_mapviewer_session]);
        g_mapviewer_session[1]=0;
	}
}

// Create a new map handle or get the current handle
function mapviewer_handle(par,w,h,type)
{
    if (!g_mapviewer_handle[1])
    {
        var res=mapviewer_message(par, "MapViewerControl","CreateMapViewInstance", mapviewer_session(par).concat(["structure",["uint16",w,"uint16",h],"int32",type]));
        g_mapviewer_handle[1]=res[3];
    }
    return g_mapviewer_handle;
}

// Delete the map handle if exists
function mapviewer_handle_clear(par)
{
    if (g_mapviewer_handle[1]) {
        var res=mapviewercontrol_message(par, "ReleaseMapViewInstance", []);
        g_mapviewer_handle[1]=0;
    }
}

// Send a message to map viewer control with session handle
function mapviewercontrol_message(par, func, args)
{
    return mapviewer_message(par, "MapViewerControl", func, mapviewer_session(par).concat(g_mapviewer_handle,args));
}

// Send a message to map viewer control without session handle
function mapviewercontrol_get(par, func, args)
{
    return mapviewer_message(par, "MapViewerControl", func, g_mapviewer_handle,args);
}

function mapviewer_GetMapViewScale(dbusIf)
{
    return mapviewercontrol_get(dbusIf,"GetMapViewScale", []);
}

function mapviewer_GetScaleList(dbusIf)
{
    return mapviewercontrol_get(dbusIf,"GetScaleList", []);
}

function mapviewer_GetDisplayedRoutes(dbusIf)
{
    return mapviewercontrol_get(dbusIf,"GetDisplayedRoutes", []);
}

function mapviewer_SetMapViewScale(dbusIf,scaleID)
{
    mapviewercontrol_message(dbusIf,"SetMapViewScale", ["uint16",scaleID]);
}

function mapviewer_SetMapViewScaleByDelta(dbusIf,scaleDelta)
{
    mapviewercontrol_message(dbusIf,"SetMapViewScaleByDelta", ["int16",scaleDelta]);
}

function mapviewer_GetMapViewTheme(dbusIf)
{
    return mapviewercontrol_get(dbusIf,"GetMapViewTheme", []);
}

function mapviewer_SetMapViewTheme(dbusIf,mapViewTheme)
{
    mapviewercontrol_message(dbusIf,"SetMapViewTheme", ["int32",mapViewTheme]);
}

function mapviewer_GetMapViewPerspective(dbusIf)
{
    return mapviewercontrol_get(dbusIf,"GetMapViewPerspective", []);
}

function mapviewer_SetMapViewPerspective(dbusIf,perspective)
{
    mapviewercontrol_message(dbusIf,"SetMapViewPerspective", ["int32",perspective]);
}

function mapviewer_SetFollowCarMode(dbusIf,followCarMode)
{
    mapviewercontrol_message(dbusIf,"SetFollowCarMode", ["boolean",followCarMode]);
}

function mapviewer_DisplayRoute(dbusIf,routeHandle,highlighted)
{
    var args=[];
    args=args.concat(routeHandle);
    mapviewercontrol_message(dbusIf,"DisplayRoute", args.concat("boolean",highlighted));
}

function mapviewer_SetTargetPoint(dbusIf,latitude,longitude,altitude)
{
    mapviewercontrol_message(dbusIf, "SetTargetPoint", ["structure",["double",latitude,"double",longitude,"double",altitude]]);
}

function mapviewer_SetMapViewBoundingBox(dbusIf,boundingBox)
{
    mapviewercontrol_message(dbusIf,"SetMapViewBoundingBox", boundingBox);
}

function mapviewer_GetTargetPoint(dbusIf)
{
    return mapviewercontrol_get(dbusIf,"GetTargetPoint", []);
}

function mapviewer_GetCameraValue(dbusIf,camera)
{
    return mapviewercontrol_get(dbusIf,"Get"+camera, []);
}

function mapviewer_SetCameraValue(dbusIf,camera,value)
{
    mapviewercontrol_message(dbusIf,"Set"+camera, value);
}

function mapviewer_SetMapViewRotation(dbusIf,angle)
{
    mapviewercontrol_message(dbusIf, "SetMapViewRotation", ["int32",angle,"int32",15]);
}

function mapviewer_SetCameraHeadingAngle(dbusIf,angle)
{
    mapviewercontrol_message(dbusIf, "SetCameraHeadingAngle", ["int32",angle]);
}

function mapviewer_SetCameraHeadingTrackUp(dbusIf)
{
    mapviewercontrol_message(dbusIf, "SetCameraHeadingTrackUp", []);
}

function mapviewer_SetMapViewPan(dbusIf,panningAction,x,y)
{
    mapviewercontrol_message(dbusIf, "SetMapViewPan", ["int32",panningAction,"array",["structure",["uint16",x,"uint16",y]]]);
}

function mapviewer_ConvertPixelCoordsToGeoCoords(dbusIf,x,y)
{
    return mapviewercontrol_message(dbusIf, "ConvertPixelCoordsToGeoCoords",["array",["structure",["uint16",x,"uint16",y]]]);
}

//---------------- MapViewer messages (handle 2) ----------------

// Create a new map handle or get the current handle
function mapviewer_handle2(par,w,h,type)
{
    if (!g_mapviewer_handle2[1])
    {
        var res=mapviewer_message(par, "MapViewerControl","CreateMapViewInstance", mapviewer_session(par).concat(["structure",["uint16",w,"uint16",h],"int32",type]));
        g_mapviewer_handle2[1]=res[3];
    }
    return g_mapviewer_handle2;
}

// Delete the map handle if exists
function mapviewer_handle_clear2(par)
{
    if (g_mapviewer_handle2[1]) {
        var res=mapviewercontrol_message2(par, "ReleaseMapViewInstance", []);
        g_mapviewer_handle2[1]=0;
    }
}

// Send a message to map viewer control with session handle on handle 2
function mapviewercontrol_message2(par, func, args)
{
    return mapviewer_message(par, "MapViewerControl", func, mapviewer_session(par).concat(g_mapviewer_handle2,args));
}

function mapviewer2_SetMapViewTheme(dbusIf,mapViewTheme)
{
    mapviewercontrol_message2(dbusIf,"SetMapViewTheme", ["int32",mapViewTheme]);
}

function mapviewer2_SetMapViewBoundingBox(dbusIf,boundingBox)
{
    mapviewercontrol_message2(dbusIf,"SetMapViewBoundingBox", boundingBox);
}

function mapviewer2_DisplayRoute(dbusIf,routeHandle,highlighted)
{
    var args=[];
    args=args.concat(routeHandle);
    mapviewercontrol_message2(dbusIf,"DisplayRoute", args.concat("boolean",highlighted));
}

//---------------- Mapviewer Configuration messages ----------------

function mapviewer_configuration_message(par, func, args)
{
    return mapviewer_message(par, "Configuration", func,args);
}

function mapviewer_configuration_GetSupportedLocales(dbusIf)
{
    return mapviewer_configuration_message(dbusIf,"GetSupportedLocales",[]);
}

function mapviewer_configuration_GetLocale(dbusIf)
{
    return mapviewer_configuration_message(dbusIf,"GetLocale",[]);
}

function mapviewer_configuration_SetLocale(dbusIf,language,country,script)
{
    mapviewer_configuration_message(dbusIf,"SetLocale",["string",language,"string",country,"string",script]);
}

function mapviewer_configuration_GetUnitsOfMeasurement(dbusIf)
{
    return mapviewer_configuration_message(dbusIf,"GetUnitsOfMeasurement",[]);
}

function mapviewer_configuration_SetUnitsOfMeasurementLength(dbusIf,unit)
{
    mapviewer_configuration_message(dbusIf,"SetUnitsOfMeasurement",["map",["int32",NAVIGATIONCORE_LENGTH,"int32",unit]]);
}

// -------------------- POISearch dbus messages --------------------

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
function poisearch_handle(par) {
    if (!g_poisearch_handle[1])
    {
        var res=poisearch_message_get(par, "CreatePoiSearchHandle", []);
        g_poisearch_handle[1]=res[1];
    }
    return g_poisearch_handle;
}

// Delete the poisearch handle if exists
function poisearch_handle_clear(par)
{
    if (g_poisearch_handle[1]) {
        poisearch_message(par, "DeletePoiSearchHandle", []);
        g_poisearch_handle[1]=0;
    }
}

function poisearch_StartPoiSearch(dbusIf,inputString,sortOption)
{
    poisearch_message(dbusIf,"StartPoiSearch",["string",inputString,"int32",sortOption]);
}

function poisearch_SetCenter(dbusIf,latitude,longitude,altitude)
{
    poisearch_message(dbusIf, "SetCenter", ["structure",["double",latitude,"double",longitude,"double",altitude]]);
}

function poisearch_SetCategories(dbusIf,poiCategories)
{
    var value=[];
    for(var i=0;i<poiCategories.length;i+=1)
    {
        value=value.concat(["structure",["uint32",poiCategories[i][0],"uint32",poiCategories[i][1]]]);
    }

    poisearch_message(dbusIf, "SetCategories", ["array",value]);
}

function poisearch_GetAvailableCategories(dbusIf)
{
    return poisearch_message_get(dbusIf,"GetAvailableCategories",[]);
}

function poisearch_RequestResultList(dbusIf,offset,maxWindowSize,attributeList)
{
    var value=[];
    for(var i=0;i<attributeList.length;i+=1)
    {
        value=value.concat(["uint32",attributeList[i]]);
    }
    return poisearch_message(dbusIf,"RequestResultList",["uint16",offset,"uint16",maxWindowSize,"array",value]);
}

function poisearch_GetPoiDetails(dbusIf,ids)
{
    var value=[];
    for(var i=0;i<ids.length;i+=1)
    {
        value=value.concat(["uint32",ids[i]]);
    }
    return poisearch_message_get(dbusIf,"GetPoiDetails",["array",value]);
}

//----------------- Trip Computer messages -----------------

// Send a message to tripcomputer (basic)
function tripcomputer_message(par, func, args)
{
	return demonstrator_message(par, "TripComputer", func, args);
}

// Send a message to fuel stop advisor (basic)
function fuelstopadvisor_message(par, func, args)
{
	return demonstrator_message(par, "FuelStopAdvisor", func, args);
}

function fuelstopadvisor_ReleaseRouteHandle(dbusIf,routeHandle)
{
    fuelstopadvisor_message(dbusIf,"ReleaseRouteHandle",routeHandle);
}

function fuelstopadvisor_SetRouteHandle(dbusIf,routeHandle)
{
    fuelstopadvisor_message(dbusIf,"SetRouteHandle",routeHandle);
}

function fuelstopadvisor_SetFuelAdvisorSettings(dbusIf,advisorMode,distanceThreshold)
{
    fuelstopadvisor_message(dbusIf,"SetFuelAdvisorSettings",["boolean",advisorMode,"uint8",distanceThreshold]);
}

function fuelstopadvisor_GetTripData(dbusIf,trip)
{
    return fuelstopadvisor_message(dbusIf,"GetTripData",["uint8",trip]);
}

function fuelstopadvisor_GetInstantData(dbusIf)
{
    return fuelstopadvisor_message(dbusIf,"GetInstantData",[]);
}

function fuelstopadvisor_ResetTripData(dbusIf,trip)
{
    fuelstopadvisor_message(dbusIf,"ResetTripData",["uint8",trip]);
}


