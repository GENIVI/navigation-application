/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2016, PCA Peugeot Citroen
*
* \file genivi-capi.js
*
* \brief This file is part of the navigation hmi. It defines basic functions used by the QML files, for the CommonAPI version of the FSA.
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

var g_nav_session_handle=["uint32",0];
var g_locationinput_handle=["uint32",0];
var g_routing_handle=["uint32",0];
var g_mapviewer_session_handle=["uint32",0];
var g_mapviewer_handle=["uint32",0];
var g_poisearch_handle=["uint32",0];
var g_language,g_country,g_script; //initialized by conf file

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

//initialized by conf file
var simulationMode;
var showroom;
var autoguidance;
var verbose;
var dlt;
var radius; //radius in m around the vehicle to search for the refill stations
var maxResultListSize; //max size of elements to return as a result
var g_default_category_name;

var guidance_activated;
var route_calculated;
var reroute_requested;
var location_input_activated;
var vehicle_located;
var destination_defined;

function setDestinationDefined(dltInterface,arg)
{
    destination_defined=arg;
    if(verbose===true){
        hookMessage(dltInterface,"Destination defined",destination_defined);
    }
}

function setVehicleLocated(dltInterface,arg)
{
    vehicle_located=arg;
    if(verbose===true){
        hookMessage(dltInterface,"Vehicle located",vehicle_located);
    }
}

function setRouteCalculated(dltInterface,arg)
{
    route_calculated=arg;
    if(verbose===true){
        hookMessage(dltInterface,"Route calculated",route_calculated);
    }
}

function setGuidanceActivated(dltInterface,arg)
{
    guidance_activated=arg;
    if(verbose===true){
        hookMessage(dltInterface,"Guidance activated",guidance_activated);
    }
}

function setLocationInputActivated(dltInterface,arg)
{
    location_input_activated=arg;
    if(verbose===true){
        hookMessage(dltInterface,"Location input activated",location_input_activated);
    }
}

function setRerouteRequested(dltInterface,arg)
{
    reroute_requested=arg;
    if(verbose===true){
        hookMessage(dltInterface,"Reroute requested",reroute_requested);
    }
}

var scaleList;
var minZoomId;
var maxZoomId;
var currentZoomId;

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
var offset=0; //offset of the start record to get on the list of pois
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

// Give the formated duration
function duration(seconds)
{
    if (seconds >= 3600) {
        return Math.floor(seconds/3600)+":"+(Math.floor(seconds/60)%60)+":"+(seconds%60);
    } else {
        return Math.floor(seconds/60)+":"+(seconds%60);
    }
}

// Give the formated time (with reset of hours if >= 24, only 24h format is supported)
// it supposes the time is less than 48 h
function time(seconds)
{
    if (seconds >= 3600) {
        if (Math.floor(seconds/3600) < 24)
            return Math.floor(seconds/3600)+":"+(Math.floor(seconds/60)%60)+":"+(seconds%60);
        else
            return (Math.floor(seconds/3600)-24)+":"+(Math.floor(seconds/60)%60)+":"+(seconds%60);
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
var allKeys;
var germanAllKeys="\b ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
var frenchAllKeys="\b ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
var englishAllKeys="\b ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
var japaneseAllKeys="\b ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789あかさたなはまやらわいきしちにひみりをうくすつぬふむゆるんえけせてねへめれ”おこそとのほもよろ°アカサタナハマヤラワイキシチニヒミリヲウクスツヌフムユルンエケセテネヘメレオコソトノホモヨロ";

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
        allKeys=englishAllKeys;
        kbdFirstLayout="ABC";
        kbdSecondLayout="123";
        kbdColumns=8; //number of rows per line
        kbdColumnRatio=4; //size of row spacing (ratio)
        kbdLines=4; //number of lines
        kbdLineRatio=4; //size of line spacing (ratio)
    }else{
        if(g_language==="fra"){
            keyboardLayout=frenchLayout;
            allKeys=frenchAllKeys;
            kbdFirstLayout="ABC";
            kbdSecondLayout="123";
            kbdColumns=8; //number of rows per line
            kbdColumnRatio=4; //size of row spacing (ratio)
            kbdLines=4; //number of lines
            kbdLineRatio=4; //size of line spacing (ratio)
        }else{
            if(g_language==="jpn"){
                keyboardLayout=japaneseLayout;
                allKeys=japaneseAllKeys;
                kbdFirstLayout="かな";
                kbdSecondLayout="カナ";
                kbdColumns=10; //number of rows per line
                kbdColumnRatio=4; //size of row spacing (ratio)
                kbdLines=6; //number of lines
                kbdLineRatio=4; //size of line spacing (ratio)
            }else{
                if(g_language==="deu"){
                    keyboardLayout=germanLayout;
                    allKeys=germanAllKeys;
                    kbdFirstLayout="ABC";
                    kbdSecondLayout="123";
                    kbdColumns=8; //number of rows per line
                    kbdColumnRatio=4; //size of row spacing (ratio)
                    kbdLines=4; //number of lines
                    kbdLineRatio=4; //size of line spacing (ratio)
                }else{
                    //default
                    keyboardLayout=germanLayout;
                    allKeys=germanAllKeys;
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

function hookMessage(dltInterface,subject,arg)
{
    if(dlt===true)
        dltInterface.log_info_msg(subject+": "+arg);
    else
        console.log(subject+": "+arg);
}

//----------------- Management of the DBus messages -----------------

function hookMethod(dltInterface,arg)
{
    if(dlt===true)
        dltInterface.log_info_msg(arg);
    else
        console.log("Method: ",arg);
}

// Send a dbus message to layer manager
function lm_message(dbusInterface, dltInterface, func, args)
{
//    console.log("Method: ",func);
    return dbusInterface.message("org.genivi.layermanagementservice","/org/genivi/layermanagementservice","org.genivi.layermanagementservice", func, args);
}

// Send a message to navigationcore (basic)
function navigationcore_message(dbusInterface, dltInterface, iface, func, args)
{
    hookMethod(dltInterface,func);
    return dbusInterface.message("org.genivi.navigation.navigationcore."+iface+".v4_0_"+iface,"/"+iface,"org.genivi.navigation.navigationcore."+iface+".v4_0", func, args);
}

// Send a message to mapviewer (basic)
function mapviewer_message(dbusInterface, dltInterface, iface, func, args)
{
    hookMethod(dltInterface,func);
    return dbusInterface.message("org.genivi.navigation.mapviewer."+iface+".v4_0_"+iface,"/"+iface,"org.genivi.navigation.mapviewer."+iface+".v4_0", func, args);
}

// Send a message to poiservice (basic)
function poi_message(dbusInterface, dltInterface, iface, func, args)
{
    hookMethod(dltInterface,func);
    return dbusInterface.message("org.genivi.navigation.poiservice."+iface+".v2_0_"+iface,"/"+iface,"org.genivi.navigation.poiservice."+iface+".v2_0", func, args);
}

// Send a message to demonstrator (basic)
function demonstrator_message(dbusInterface, dltInterface, iface, func, args)
{
    hookMethod(dltInterface,func);
    return dbusInterface.message("org.genivi.demonstrator."+iface+".v1_0_"+iface,"/"+iface,"org.genivi.demonstrator."+iface+".v1_0", func, args);
}

//----------------- DBus signals -----------------
function hookSignal(dltInterface,arg)
{
    if(dlt===true)
        dltInterface.log_info_msg(arg);
    else
        console.log("Signal: ",arg);
}

function connect_simulationStatusChangedSignal(interface,menu)
{
    return interface.connect("","/MapMatchedPosition","org.genivi.navigation.navigationcore.MapMatchedPosition.v4_0","simulationStatusChanged",menu,"simulationStatusChanged");
}

function connect_simulationSpeedChangedSignal(interface,menu)
{
    return interface.connect("","/MapMatchedPosition","org.genivi.navigation.navigationcore.MapMatchedPosition.v4_0","simulationSpeedChanged",menu,"simulationSpeedChanged");
}

function connect_searchStatusSignal(interface,menu)
{
    return interface.connect("","/LocationInput","org.genivi.navigation.navigationcore.LocationInput.v4_0","searchStatus",menu,"searchStatus");
}

function connect_searchResultListSignal(interface,menu)
{
    return interface.connect("","/LocationInput","org.genivi.navigation.navigationcore.LocationInput.v4_0","searchResultList",menu,"searchResultList");
}

function connect_spellResultSignal(interface,menu)
{
    return interface.connect("","/LocationInput","org.genivi.navigation.navigationcore.LocationInput.v4_0","spellResult",menu,"spellResult");
}

function connect_guidanceStatusChangedSignal(interface,menu)
{
    return interface.connect("","/Guidance","org.genivi.navigation.navigationcore.Guidance.v4_0","guidanceStatusChanged",menu,"guidanceStatusChanged");
}

function connect_guidanceWaypointReachedSignal(interface,menu)
{
    return interface.connect("","/Guidance","org.genivi.navigation.navigationcore.Guidance.v4_0","waypointReached",menu,"guidanceWaypointReached");
}

function connect_guidanceManeuverChangedSignal(interface,menu)
{
    return interface.connect("","/Guidance","org.genivi.navigation.navigationcore.Guidance.v4_0","maneuverChanged",menu,"guidanceManeuverChanged");
}

function connect_guidancePositionOnRouteChangedSignal(interface,menu)
{
    return interface.connect("","/Guidance","org.genivi.navigation.navigationcore.Guidance.v4_0","positionOnRouteChanged",menu,"guidancePositionOnRouteChanged");
}

function connect_mapmatchedpositionPositionUpdateSignal(interface,menu)
{
    return interface.connect("","/MapMatchedPosition","org.genivi.navigation.navigationcore.MapMatchedPosition.v4_0","positionUpdate",menu,"mapmatchedpositionPositionUpdate");
}

function connect_mapmatchedpositionAddressUpdateSignal(interface,menu)
{
    return interface.connect("","/MapMatchedPosition","org.genivi.navigation.navigationcore.MapMatchedPosition.v4_0","addressUpdate",menu,"mapmatchedpositionAddressUpdate");
}

function connect_routeCalculationSuccessfulSignal(interface,menu)
{
    return interface.connect("","/Routing","org.genivi.navigation.navigationcore.Routing.v4_0","routeCalculationSuccessful",menu,"routeCalculationSuccessful");
}

function connect_routeCalculationFailedSignal(interface,menu)
{
    return interface.connect("","/Routing","org.genivi.navigation.navigationcore.Routing.v4_0","routeCalculationFailed",menu,"routeCalculationFailed");
}

function connect_routeCalculationProgressUpdateSignal(interface,menu)
{
    return interface.connect("","/Routing","org.genivi.navigation.navigationcore.Routing.v4_0","routeCalculationProgressUpdate",menu,"routeCalculationProgressUpdate");
}

function connect_currentSelectionCriterionSignal(interface,menu)
{
    return interface.connect("","/LocationInput","org.genivi.navigation.navigationcore.LocationInput.v4_0","currentSelectionCriterion",menu,"currentSelectionCriterion");
}

function connect_contentUpdatedSignal(interface,menu)
{
    return interface.connect("","/LocationInput","org.genivi.navigation.navigationcore.LocationInput.v4_0","contentUpdated",menu,"contentUpdated");
}

function connect_configurationChangedSignal(interface,menu)
{
    return interface.connect("","/Configuration","org.genivi.navigation.navigationcore.Configuration.v4_0","configurationChanged",menu,"configurationChanged");
}

function connect_tripDataUpdatedSignal(interface,menu)
{
    return interface.connect("","/FuelStopAdvisor","org.genivi.demonstrator.FuelStopAdvisor.v1_0","tripDataUpdated",menu,"tripDataUpdated");
}

function connect_fuelStopAdvisorWarningSignal(interface,menu)
{
    return interface.connect("","/FuelStopAdvisor","org.genivi.demonstrator.FuelStopAdvisor.v1_0","fuelStopAdvisorWarning",menu,"fuelStopAdvisorWarning");
}

function connect_mapViewScaleChangedSignal(interface,menu)
{
    return interface.connect("","/MapViewerControl","org.genivi.navigation.mapviewer.MapViewerControl.v4_0","mapViewScaleChanged",menu,"mapViewScaleChanged");
}

function connect_mapViewPerspectiveChangedSignal(interface,menu)
{
    return interface.connect("","/MapViewerControl","org.genivi.navigation.mapviewer.MapViewerControl.v4_0","mapViewPerspectiveChanged",menu,"mapViewPerspectiveChanged");
}

//----------------- NavigationCore dbus messages -----------------

//----------------- Navigation core Session messages -----------------

function navigationcore_session_message(dbusInterface, dltInterface, func, args)
{
    return navigationcore_message(dbusInterface, dltInterface, "Session", func, args);
}

function navigationcore_session_CreateSession(dbusInterface,dltInterface)
{
    return navigationcore_session_message(dbusInterface,dltInterface,"createSession", ["string","TestHMI"]);
}

function navigationcore_session_DeleteSession(dbusInterface,dltInterface)
{
    return navigationcore_session_message(dbusInterface,dltInterface,"deleteSession", g_nav_session_handle);
}

// Create a new session or get the current session
function navigationcore_session() {
    return g_nav_session_handle;
}

function navigationcore_session_GetVersion(dbusInterface,dltInterface)
{
    return navigationcore_session_message(dbusInterface,dltInterface,"getVersion",[]);
}


//----------------- Navigation core Configuration messages -----------------

function navigationcore_configuration_message(dbusInterface, dltInterface, func, args)
{
    return navigationcore_message(dbusInterface, dltInterface, "Configuration", func,args);
}

function navigationcore_configuration_GetSupportedLocales(dbusInterface,dltInterface)
{
    return navigationcore_configuration_message(dbusInterface,dltInterface,"getSupportedLocales",[]);
}

function navigationcore_configuration_GetLocale(dbusInterface,dltInterface)
{
    return navigationcore_configuration_message(dbusInterface,dltInterface,"getLocale",[]);
}

function navigationcore_configuration_SetLocale(dbusInterface,dltInterface,language,country,script)
{
    navigationcore_configuration_message(dbusInterface,dltInterface,"setLocale",["string",language,"string",country,"string",script]);
}

function navigationcore_configuration_GetUnitsOfMeasurement(dbusInterface,dltInterface)
{
    return navigationcore_configuration_message(dbusInterface,dltInterface,"getUnitsOfMeasurement",[]);
}

function navigationcore_configuration_SetUnitsOfMeasurementLength(dbusInterface,dltInterface,unit)
{
    navigationcore_configuration_message(dbusInterface,dltInterface,"setUnitsOfMeasurement",["map",["int32",NAVIGATIONCORE_LENGTH,"int32",unit]]);
}

//----------------- LocationInput messages -----------------
function locationinput_CreateLocationInput(dbusInterface,dltInterface)
{
    return navigationcore_message(dbusInterface, dltInterface, "LocationInput","createLocationInput", g_nav_session_handle);
}

function locationinput_DeleteLocationInput(dbusInterface,dltInterface)
{
    return locationinput_message(dbusInterface, dltInterface, "deleteLocationInput", []);
}

// Get the current handle
function locationinput_handle(dbusInterface,dltInterface)
{
    return g_locationinput_handle;
}

function locationinput_message(dbusInterface, dltInterface, func, args)
{
    return navigationcore_message(dbusInterface, dltInterface, "LocationInput", func, navigationcore_session().concat(locationinput_handle(dbusInterface),args));
}

function locationinput_Spell(dbusInterface,dltInterface,inputCharacter,maxWindowSize)
{
    locationinput_message(dbusInterface,dltInterface,"spell",["string",inputCharacter,"uint16",maxWindowSize]);
}

function locationinput_RequestListUpdate(dbusInterface,dltInterface,offset,maxWindowSize)
{
    locationinput_message(dbusInterface,dltInterface,"requestListUpdate",["uint16",offset,"uint16",maxWindowSize]);
}

function locationinput_SetSelectionCriterion(dbusInterface,dltInterface,selectionCriterion)
{
    locationinput_message(dbusInterface,dltInterface,"setSelectionCriterion",["int32",selectionCriterion]);
}

function locationinput_Search(dbusInterface,dltInterface,inputString,maxWindowSize)
{
    locationinput_message(dbusInterface,dltInterface,"search",["string",inputString,"uint16",maxWindowSize]);
}

function locationinput_SelectEntry(dbusInterface,dltInterface,index)
{
    locationinput_message(dbusInterface,dltInterface,"selectEntry",["uint16",index]);
}

//----------------- Routing messages -----------------

// Send a message to routing with session handle and route handle
function routing_message(dbusInterface, dltInterface, func, args)
{ //session handle sent
    return navigationcore_message(dbusInterface, dltInterface, "Routing", func, navigationcore_session().concat(routing_handle(),args));
}

// Send a message to routing with route handle
function routing_get(dbusInterface, dltInterface, func, args)
{
    return navigationcore_message(dbusInterface, dltInterface, "Routing", func, routing_handle().concat(args));
}

// Send a message to routing
function routing(dbusInterface, dltInterface, func, args)
{
    return navigationcore_message(dbusInterface, dltInterface, "Routing", func, args);
}

function routing_CreateRoute(dbusInterface,dltInterface)
{
    return navigationcore_message(dbusInterface, dltInterface, "Routing","createRoute", navigationcore_session(dbusInterface,dltInterface));
}

function routing_DeleteRoute(dbusInterface,dltInterface,routeHandle)
{
    return routing_message(dbusInterface, dltInterface, "deleteRoute", routeHandle);
}

// Get the current handle
function routing_handle() {
    return g_routing_handle;
}

function routing_GetRouteOverviewTimeAndDistance(dbusInterface,dltInterface)
{
    var valuesToReturn=[], pref=[];
    pref=pref.concat("int32",NAVIGATIONCORE_TOTAL_TIME,"int32",NAVIGATIONCORE_TOTAL_DISTANCE);
    valuesToReturn = valuesToReturn.concat("array",[pref]);

    return routing_get(dbusInterface,dltInterface,"getRouteOverview",valuesToReturn);
}

function routing_GetCostModel(dbusInterface,dltInterface)
{
    return routing_get(dbusInterface,dltInterface,"getCostModel",[]);
}

function routing_SetCostModel(dbusInterface,dltInterface,costModel)
{
    var res=routing_message(dbusInterface,dltInterface,"setCostModel",["int32",costModel]);
}

function routing_GetSupportedCostModels(dbusInterface,dltInterface)
{
    return routing(dbusInterface,dltInterface,"getSupportedCostModels",[]);
}

function routing_GetSupportedRoutePreferences(dbusInterface,dltInterface)
{
    return routing(dbusInterface,dltInterface,"getSupportedRoutePreferences",[]);
}

function routing_GetRoutePreferences(dbusInterface,dltInterface,countryCode)
{
    return routing_get(dbusInterface,dltInterface,"getRoutePreferences",["string",countryCode]);
}

function routing_SetRoutePreferences(dbusInterface,dltInterface,countryCode)
{
    var roadMessage=["array",["structure",["int32",roadPreferenceList[NAVIGATIONCORE_FERRY],"int32",NAVIGATIONCORE_FERRY],"structure",["int32",roadPreferenceList[NAVIGATIONCORE_TOLL_ROADS],"int32",NAVIGATIONCORE_TOLL_ROADS],"structure",["int32",roadPreferenceList[NAVIGATIONCORE_HIGHWAYS_MOTORWAYS],"int32",NAVIGATIONCORE_HIGHWAYS_MOTORWAYS]]];
    var conditionMessage=["array",["structure",["int32",conditionPreferenceList[NAVIGATIONCORE_TRAFFIC_REALTIME],"int32",NAVIGATIONCORE_TRAFFIC_REALTIME]]];
    var message=["string",countryCode];
    message=message.concat(roadMessage.concat(conditionMessage));
    var res=routing_message(dbusInterface,dltInterface,"setRoutePreferences",message);
}

function routing_GetRouteSegments(dbusInterface,dltInterface,detailLevel,numberOfSegments,offset)
{
    var routeSegmentType=["int32",NAVIGATIONCORE_DISTANCE,"int32",NAVIGATIONCORE_TIME,"int32",NAVIGATIONCORE_ROAD_NAME];

    return routing_get(dbusInterface,dltInterface,"getRouteSegments",["int16",detailLevel,"array",routeSegmentType,"uint32",numberOfSegments,"uint32",offset]);
}

function latlon_to_map(latlon)
{
    return [
        "int32",NAVIGATIONCORE_LATITUDE,"structure",["uint8",3,"variant",["double",latlon['lat']]],
        "int32",NAVIGATIONCORE_LONGITUDE,"structure",["uint8",3,"variant",["double",latlon['lon']]]
    ];
}

function routing_SetWaypoints(dbusInterface,dltInterface,startFromCurrentPosition,position,destination)
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
    var res=routing_message(dbusInterface,dltInterface,"setWaypoints",message);
}

function routing_CalculateRoute(dbusInterface,dltInterface)
{
    var res=routing_message(dbusInterface,dltInterface,"calculateRoute",[]);
}

function routing_GetRouteBoundingBox(dbusInterface,dltInterface,routeHandle)
{
    var message=[];
    return navigationcore_message(dbusInterface,dltInterface, "Routing", "getRouteBoundingBox", message.concat(routeHandle));
}

//----------------- Guidance messages -----------------

// Send a message to guidance with session handle
function guidance_message(dbusInterface, dltInterface, func, args)
{
    return navigationcore_message(dbusInterface, dltInterface, "Guidance", func, navigationcore_session().concat(args));
}
// Send a message to guidance without session handle
function guidance_get(dbusInterface, dltInterface, func, args)
{
    return navigationcore_message(dbusInterface, dltInterface, "Guidance", func, args);
}

function guidance_StartGuidance(dbusInterface,dltInterface,routeHandle)
{
    guidance_message(dbusInterface,dltInterface,"startGuidance",routeHandle);
}

function guidance_StopGuidance(dbusInterface,dltInterface)
{
    guidance_message(dbusInterface,dltInterface,"stopGuidance",[]);
}

function guidance_GetGuidanceStatus(dbusInterface,dltInterface)
{
    return guidance_get(dbusInterface,dltInterface,"getGuidanceStatus",[]);
}

function guidance_GetDestinationInformation(dbusInterface,dltInterface)
{
    return guidance_get(dbusInterface,dltInterface,"getDestinationInformation",[]);
}

function guidance_GetManeuversList(dbusInterface,dltInterface,requestedNumberOfManeuvers,maneuverOffset)
{
    return guidance_get(dbusInterface,dltInterface,"getManeuversList",["uint16",requestedNumberOfManeuvers,"uint32",maneuverOffset]);
}

//---------------- Map matched position messages ----------------

// Send a message to mapmatchedposition with session handle
function mapmatchedposition_message(dbusInterface, dltInterface, func, args)
{
    return navigationcore_message(dbusInterface, dltInterface, "MapMatchedPosition", func, navigationcore_session().concat(args));
}

// Send a message to mapmatchedposition without session handle
function mapmatchedposition_get(dbusInterface, dltInterface, func, args)
{
    return navigationcore_message(dbusInterface, dltInterface, "MapMatchedPosition", func, args);
}

function mapmatchedposition_GetCurrentAddress(dbusInterface,dltInterface)
{
    var valuesToReturn=["int32",NAVIGATIONCORE_STREET];

    return mapmatchedposition_get(dbusInterface,dltInterface,"getCurrentAddress",["array",valuesToReturn]);
}

function mapmatchedposition_SetSimulationMode(dbusInterface,dltInterface,activate)
{
    mapmatchedposition_message(dbusInterface,dltInterface,"setSimulationMode",["boolean",activate]);
}

function mapmatchedposition_StartSimulation(dbusInterface,dltInterface)
{
    mapmatchedposition_message(dbusInterface,dltInterface,"startSimulation",[]);
}

function mapmatchedposition_PauseSimulation(dbusInterface,dltInterface)
{
    mapmatchedposition_message(dbusInterface,dltInterface,"pauseSimulation",[]);
}

function mapmatchedposition_GetSimulationStatus(dbusInterface,dltInterface)
{
    return mapmatchedposition_get(dbusInterface,dltInterface,"getSimulationStatus",[]);
}

function mapmatchedposition_GetSimulationSpeed(dbusInterface,dltInterface)
{
    return mapmatchedposition_get(dbusInterface,dltInterface,"getSimulationSpeed",[]);
}

function mapmatchedposition_SetSimulationSpeed(dbusInterface,dltInterface,speedFactor)
{
    mapmatchedposition_message(dbusInterface,dltInterface,"setSimulationSpeed",["uint8",speedFactor]);
}

function mapmatchedposition_SetPosition(dbusInterface,dltInterface,position)
{
    mapmatchedposition_message(dbusInterface,dltInterface,"setPosition",["map",position]);
}

function mapmatchedposition_GetPosition(dbusInterface,dltInterface)
{
    var valuesToReturn=["int32",NAVIGATIONCORE_SPEED,"int32",NAVIGATIONCORE_LATITUDE,"int32",NAVIGATIONCORE_LONGITUDE];

    return mapmatchedposition_get(dbusInterface,dltInterface,"getPosition",["array",valuesToReturn]);
}

//---------------- MapViewer messages (handle 1) ----------------
function mapviewer_session_CreateSession(dbusInterface,dltInterface)
{
    return mapviewer_message(dbusInterface, dltInterface, "Session", "createSession", ["string","TestHMI"]);
}

function mapviewer_session_DeleteSession(dbusInterface,dltInterface)
{
    return mapviewer_message(dbusInterface, dltInterface, "Session", "deleteSession", g_mapviewer_session_handle);
}

function mapviewer_CreateMapViewInstance(dbusInterface,dltInterface,width,height,type)
{
    return mapviewer_message(dbusInterface, dltInterface, "MapViewerControl","createMapViewInstance", mapviewer_session().concat(["structure",["uint16",width,"uint16",height],"int32",type]));
}

function mapviewer_ReleaseMapViewInstance(dbusInterface,dltInterface)
{
    return mapviewercontrol_message(dbusInterface, dltInterface, "releaseMapViewInstance", []);
}

// Get the current session
function mapviewer_session() {
    return g_mapviewer_session_handle;
}

// Create a new map handle or get the current handle
function mapviewer_handle(dbusInterface,w,h,type)
{
    return g_mapviewer_handle;
}

// Send a message to map viewer control with session handle
function mapviewercontrol_message(dbusInterface, dltInterface, func, args)
{
    return mapviewer_message(dbusInterface, dltInterface, "MapViewerControl", func, mapviewer_session().concat(g_mapviewer_handle,args));
}

// Send a message to map viewer control without session handle
function mapviewercontrol_get(dbusInterface, dltInterface, func, args)
{
    return mapviewer_message(dbusInterface, dltInterface, "MapViewerControl", func, g_mapviewer_handle,args);
}

function mapviewer_GetMapViewScale(dbusInterface,dltInterface)
{
    return mapviewercontrol_get(dbusInterface,dltInterface,"getMapViewScale", []);
}

function mapviewer_GetScaleList(dbusInterface,dltInterface)
{
    return mapviewercontrol_get(dbusInterface,dltInterface,"getScaleList", []);
}

function mapviewer_GetDisplayedRoutes(dbusInterface,dltInterface)
{
    return mapviewercontrol_get(dbusInterface,dltInterface,"getDisplayedRoutes", []);
}

function mapviewer_SetMapViewScale(dbusInterface,dltInterface,scaleID)
{
    mapviewercontrol_message(dbusInterface,dltInterface,"setMapViewScale", ["uint8",scaleID]);
}

function mapviewer_SetMapViewScaleByDelta(dbusInterface,dltInterface,scaleDelta)
{
    mapviewercontrol_message(dbusInterface,dltInterface,"setMapViewScaleByDelta", ["int16",scaleDelta]);
}

function mapviewer_GetMapViewTheme(dbusInterface,dltInterface)
{
    return mapviewercontrol_get(dbusInterface,dltInterface,"getMapViewTheme", []);
}

function mapviewer_SetMapViewTheme(dbusInterface,dltInterface,mapViewTheme)
{
    mapviewercontrol_message(dbusInterface,dltInterface,"setMapViewTheme", ["int32",mapViewTheme]);
}

function mapviewer_GetMapViewPerspective(dbusInterface,dltInterface)
{
    return mapviewercontrol_get(dbusInterface,dltInterface,"getMapViewPerspective", []);
}

function mapviewer_SetMapViewPerspective(dbusInterface,dltInterface,perspective)
{
    mapviewercontrol_message(dbusInterface,dltInterface,"setMapViewPerspective", ["int32",perspective]);
}

function mapviewer_SetFollowCarMode(dbusInterface,dltInterface,followCarMode)
{
    mapviewercontrol_message(dbusInterface,dltInterface,"setFollowCarMode", ["boolean",followCarMode]);
}

function mapviewer_DisplayRoute(dbusInterface,dltInterface,routeHandle,highlighted)
{
    var args=[];
    args=args.concat(routeHandle);
    mapviewercontrol_message(dbusInterface,dltInterface,"displayRoute", args.concat("boolean",highlighted));
}

function mapviewer_HideRoute(dbusInterface,dltInterface,routeHandle)
{
    var args=[];
    args=args.concat(routeHandle);
    mapviewercontrol_message(dbusInterface,dltInterface,"hideRoute", args);
}

function mapviewer_SetTargetPoint(dbusInterface,dltInterface,latitude,longitude,altitude)
{
    mapviewercontrol_message(dbusInterface,dltInterface, "setTargetPoint", ["structure",["double",latitude,"double",longitude,"double",altitude]]);
}

function mapviewer_SetMapViewBoundingBox(dbusInterface,dltInterface,boundingBox)
{
    mapviewercontrol_message(dbusInterface,dltInterface,"setMapViewBoundingBox", boundingBox);
}

function mapviewer_GetTargetPoint(dbusInterface,dltInterface)
{
    return mapviewercontrol_get(dbusInterface,dltInterface,"getTargetPoint", []);
}

function mapviewer_GetCameraValue(dbusInterface,dltInterface,camera)
{
    return mapviewercontrol_get(dbusInterface,dltInterface,"get"+camera, []);
}

function mapviewer_SetCameraValue(dbusInterface,dltInterface,camera,value)
{
    mapviewercontrol_message(dbusInterface,dltInterface,"set"+camera, value);
}

function mapviewer_SetMapViewRotation(dbusInterface,dltInterface,angle)
{
    mapviewercontrol_message(dbusInterface,dltInterface, "setMapViewRotation", ["int32",angle,"int32",15]);
}

function mapviewer_SetCameraHeadingAngle(dbusInterface,dltInterface,angle)
{
    mapviewercontrol_message(dbusInterface,dltInterface, "setCameraHeadingAngle", ["int32",angle]);
}

function mapviewer_SetCameraHeadingTrackUp(dbusInterface,dltInterface)
{
    mapviewercontrol_message(dbusInterface,dltInterface, "setCameraHeadingTrackUp", []);
}

function mapviewer_SetMapViewPan(dbusInterface,dltInterface,panningAction,x,y)
{
    mapviewercontrol_message(dbusInterface,dltInterface, "setMapViewPan", ["int32",panningAction,"structure",["uint16",x,"uint16",y]]);
}

function mapviewer_ConvertPixelCoordsToGeoCoords(dbusInterface,dltInterface,x,y)
{
    return mapviewercontrol_message(dbusInterface,dltInterface, "convertPixelCoordsToGeoCoords",["array",["structure",["uint16",x,"uint16",y]]]);
}

function initScale(dbusInterface,dltInterface)
{
    var res=mapviewer_GetScaleList(dbusInterface,dltInterface);
    scaleList=res[1];
    minZoomId=scaleList[1][1];
    maxZoomId=scaleList[scaleList.length-1][1];
}

//---------------- Mapviewer Configuration messages ----------------

function mapviewer_configuration_message(dbusInterface, dltInterface, func, args)
{
    return mapviewer_message(dbusInterface, dltInterface, "Configuration", func,args);
}

function mapviewer_configuration_GetSupportedLocales(dbusInterface,dltInterface)
{
    return mapviewer_configuration_message(dbusInterface,dltInterface,"getSupportedLocales",[]);
}

function mapviewer_configuration_GetLocale(dbusInterface,dltInterface)
{
    return mapviewer_configuration_message(dbusInterface,dltInterface,"getLocale",[]);
}

function mapviewer_configuration_SetLocale(dbusInterface,dltInterface,language,country,script)
{
    mapviewer_configuration_message(dbusInterface,dltInterface,"setLocale",["string",language,"string",country,"string",script]);
}

function mapviewer_configuration_GetUnitsOfMeasurement(dbusInterface,dltInterface)
{
    return mapviewer_configuration_message(dbusInterface,dltInterface,"getUnitsOfMeasurement",[]);
}

function mapviewer_configuration_SetUnitsOfMeasurementLength(dbusInterface,dltInterface,unit)
{
    mapviewer_configuration_message(dbusInterface,dltInterface,"setUnitsOfMeasurement",["map",["int32",NAVIGATIONCORE_LENGTH,"int32",unit]]);
}

// -------------------- POISearch dbus messages --------------------

// Send a message to poisearch with session handle
function poisearch_message(dbusInterface, dltInterface, func, args)
{ //session handle sent
    return poi_message(dbusInterface, dltInterface, "POISearch", func, poisearch_handle().concat(args));
}

// Send a message to poisearch without session handle
function poisearch_message_get(dbusInterface, dltInterface, func, args)
{
    return poi_message(dbusInterface, dltInterface, "POISearch", func, args);
}

function poisearch_CreatePoiSearchHandle(dbusInterface,dltInterface)
{
    return poisearch_message_get(dbusInterface, dltInterface, "createPoiSearchHandle", []);
}

function poisearch_DeletePoiSearchHandle(dbusInterface,dltInterface)
{
    poisearch_message(dbusInterface, dltInterface, "deletePoiSearchHandle", []);
}

// Create a new poisearch handle or get the current handle
function poisearch_handle(dbusInterface,dltInterface) {
    return g_poisearch_handle;
}

// Delete the poisearch handle if exists
function poisearch_handle_clear(dbusInterface,dltInterface)
{
    if (g_poisearch_handle[1]) {
        poisearch_message(dbusInterface, dltInterface, "deletePoiSearchHandle", []);
        g_poisearch_handle[1]=0;
    }
}

function poisearch_StartPoiSearch(dbusInterface,dltInterface,inputString,sortOption)
{
    poisearch_message(dbusInterface,dltInterface,"startPoiSearch",["string",inputString,"int32",sortOption]);
}

function poisearch_SetCenter(dbusInterface,dltInterface,latitude,longitude,altitude)
{
    poisearch_message(dbusInterface,dltInterface, "setCenter", ["structure",["double",latitude,"double",longitude,"double",altitude]]);
}

function poisearch_SetCategories(dbusInterface,dltInterface,poiCategories)
{
    var value=[];
    for(var i=0;i<poiCategories.length;i+=1)
    {
        value=value.concat(["structure",["uint32",poiCategories[i][0],"uint32",poiCategories[i][1]]]);
    }

    poisearch_message(dbusInterface,dltInterface, "setCategories", ["array",value]);
}

function poisearch_GetAvailableCategories(dbusInterface,dltInterface)
{
    return poisearch_message_get(dbusInterface,dltInterface,"getAvailableCategories",[]);
}

function poisearch_RequestResultList(dbusInterface,dltInterface,offset,maxWindowSize,attributeList)
{
    var value=[];
    for(var i=0;i<attributeList.length;i+=1)
    {
        value=value.concat(["uint32",attributeList[i]]);
    }
    return poisearch_message(dbusInterface,dltInterface,"requestResultList",["uint16",offset,"uint16",maxWindowSize,"array",value]);
}

function poisearch_GetPoiDetails(dbusInterface,dltInterface,ids)
{
    var value=[];
    for(var i=0;i<ids.length;i+=1)
    {
        value=value.concat(["uint32",ids[i]]);
    }
    return poisearch_message_get(dbusInterface,dltInterface,"getPoiDetails",["array",value]);
}

//----------------- Trip Computer messages -----------------

// Send a message to tripcomputer (basic)
function tripcomputer_message(dbusInterface, dltInterface, func, args)
{
    return demonstrator_message(dbusInterface, dltInterface, "TripComputer", func, args);
}

// Send a message to fuel stop advisor (basic)
function fuelstopadvisor_message(dbusInterface, dltInterface, func, args)
{
    return demonstrator_message(dbusInterface, dltInterface, "FuelStopAdvisor", func, args);
}

function fuelstopadvisor_ReleaseRouteHandle(dbusInterface,dltInterface,routeHandle)
{
    fuelstopadvisor_message(dbusInterface,dltInterface,"releaseRouteHandle",routeHandle);
}

function fuelstopadvisor_SetRouteHandle(dbusInterface,dltInterface,routeHandle)
{
    fuelstopadvisor_message(dbusInterface,dltInterface,"setRouteHandle",routeHandle);
}

function fuelstopadvisor_SetFuelAdvisorSettings(dbusInterface,dltInterface,advisorMode,distanceThreshold)
{
    fuelstopadvisor_message(dbusInterface,dltInterface,"setFuelAdvisorSettings",["boolean",advisorMode,"uint8",distanceThreshold]);
}

function fuelstopadvisor_GetTripData(dbusInterface,dltInterface,trip)
{
    return fuelstopadvisor_message(dbusInterface,dltInterface,"getTripData",["uint8",trip]);
}

function fuelstopadvisor_GetInstantData(dbusInterface,dltInterface)
{
    return fuelstopadvisor_message(dbusInterface,dltInterface,"getInstantData",[]);
}

function fuelstopadvisor_ResetTripData(dbusInterface,dltInterface,trip)
{
    fuelstopadvisor_message(dbusInterface,dltInterface,"resetTripData",["uint8",trip]);
}
