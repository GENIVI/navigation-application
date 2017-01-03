/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2017, PSA GROUPE
*
* \file NavigationAppSearch.qml
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
import "Core/style-sheets/NavigationAppSearch-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

NavigationAppHMIMenu {
    id: menu
    property string pagefile:"NavigationAppSearch"

    property real criterion;
    property string extraspell;
    property string routeText:" "
    property real lat
    property real lon
    property bool keyboardActivated: false
    property string currentTextToSearch
    property real searchWindow: 10
    property bool destinationValid: false
    property real routeListSegments: 1000
    property bool vehicleLocated: false

    //------------------------------------------//
    // Management of the DBus exchanges
    //------------------------------------------//
    DBusIf {
        id: dbusIf
    }

    property Item currentSelectionCriterionSignal;
    function currentSelectionCriterion(args)
    {// locationInputHandle 1, selectionCriterion 3
        Genivi.hookSignal("currentSelectionCriterion");
        var selectionCriterion=args[3];
        Genivi.entrycriterion = selectionCriterion;
        if (Genivi.preloadMode === true) {
            Genivi.locationinput_Search(dbusIf,currentTextToSearch,searchWindow); //launch search
        }
    }

    property Item searchStatusSignal;
    function searchStatus(args)
    { //locationInputHandle 1, statusValue 3
        var statusValue=args[3];
        Genivi.hookSignal("searchStatus");
        if (keyboardActivated === true)
        {
            if (statusValue === Genivi.NAVIGATIONCORE_SEARCHING) {
                listArea.model.clear();
                keyboardArea.destination.text.color='red';  //(Searching)
            } else {
                if (statusValue === Genivi.NAVIGATIONCORE_FINISHED)
                {
                    keyboardArea.destination.text.color='white';
                    Genivi.locationinput_RequestListUpdate(dbusIf,0,10);
                }
            }
        }
        else
        {
            if (statusValue === Genivi.NAVIGATIONCORE_FINISHED)
            {
                Genivi.locationinput_SelectEntry(dbusIf,Genivi.entryselectedentry);
                if (Genivi.preloadMode === true)
                {
                    if (Genivi.entrycriterion === countryValue.criterion)
                    {
                        if (Genivi.address[Genivi.NAVIGATIONCORE_CITY] !== "")
                        {
                            cityValue.text=Genivi.address[Genivi.NAVIGATIONCORE_CITY];
                            accept(cityValue);
                            streetValue.disabled=false;
                        }
                        else
                            Genivi.preloadMode=false;
                    }
                    else
                    {
                        if (Genivi.entrycriterion === cityValue.criterion)
                        {
                            if (Genivi.address[Genivi.NAVIGATIONCORE_STREET] !== "")
                            {
                                streetValue.text=Genivi.address[Genivi.NAVIGATIONCORE_STREET];
                                accept(streetValue);
                                numberValue.disabled=false;
                            }

                        }
                        else
                        {
                            if (Genivi.entrycriterion === streetValue.criterion)
                            {
                                // no number managed for the moment
                                Genivi.preloadMode=false;
                            }
                            else
                            {
                                Genivi.preloadMode=false;
                                console.log("Error when load a preloaded address");
                            }
                        }
                    }
                }
            }
        }

    }

    property Item searchResultListSignal;
    function searchResultList(args)
    {
        if (keyboardActivated === true)
        {
            Genivi.hookSignal("searchResultList");
            var model=listArea.model;
            var windowOffset=args[5];
            var resultListWindow=args[9];
            var offset=args[5];
            var array=args[9];
            var numberOfItems=0;
            for (var i=0 ; i < resultListWindow.length ; i+=2) {
                for (var j = 0 ; j < resultListWindow[i+1].length ; j+=4) {
                    if (resultListWindow[i+1][j+1] === criterion) {
                        model.append({"name":resultListWindow[i+1][j+3][3][1],"number":(i/2)+windowOffset+1});
                        numberOfItems+=1;
                    }
                }
            }
            if(numberOfItems===1) {
                // Set value of corresponding field and hide keyboard and list eventually
                Genivi.locationinput_SelectEntry(dbusIf,0);
                manageAddressItem();
            }
        }
        else
        {
            Genivi.hookSignal("searchResultList");
        }
    }

    property Item contentUpdatedSignal;
    function contentUpdated(args)
    { //locationInputHandle 1, guidable 3, availableSelectionCriteria 5, address 7
        Genivi.hookSignal("contentUpdated");
        // Check if the destination is guidable
        var guidable=args[3];
        if (guidable) {
            destinationValid=true;
        }
        else
        {
            destinationValid=false;
            //to do something is it's not guidable
        }

        // Manage the available entries
        var availableSelectionCriteria=args[5];
        countryValue.disabled=true;
        cityValue.disabled=true;
        streetValue.disabled=true;
        numberValue.disabled=true;
        for (var i=0 ; i < args.length ; i++) {
            if (availableSelectionCriteria[i] == Genivi.NAVIGATIONCORE_COUNTRY) countryValue.disabled=false;
            if (availableSelectionCriteria[i] == Genivi.NAVIGATIONCORE_CITY) cityValue.disabled=false;
            if (availableSelectionCriteria[i] == Genivi.NAVIGATIONCORE_STREET) streetValue.disabled=false;
            if (availableSelectionCriteria[i] == Genivi.NAVIGATIONCORE_HOUSENUMBER) numberValue.disabled=false;
        }
        if (countryValue.disabled)
            countryValue.text="";
        if (cityValue.disabled)
            cityValue.text="";
        if (streetValue.disabled)
            streetValue.text="";
        if (numberValue.disabled)
            numberValue.text="";

        // Manage the content
        var address=args[7];
        countryValue.text="";
        cityValue.text="";
        streetValue.text="";
        numberValue.text="";
        if (Genivi.preloadMode === false)
        {
            Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY]="";
            Genivi.address[Genivi.NAVIGATIONCORE_CITY]="";
            Genivi.address[Genivi.NAVIGATIONCORE_STREET]="";
            Genivi.address[Genivi.NAVIGATIONCORE_HOUSENUMBER]="";
        }

        for (var i=0 ; i < address.length ; i+=4) {
            if (address[i+1] == Genivi.NAVIGATIONCORE_LATITUDE) lat=address[i+3][3][1];
            if (address[i+1] == Genivi.NAVIGATIONCORE_LONGITUDE) lon=address[i+3][3][1];
            if (address[i+1] == Genivi.NAVIGATIONCORE_COUNTRY)  {
                countryValue.text=address[i+3][3][1];
                Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY]=countryValue.text;
            }
            if (address[i+1] == Genivi.NAVIGATIONCORE_CITY) {
                cityValue.text=address[i+3][3][1];
                Genivi.address[Genivi.NAVIGATIONCORE_CITY]=cityValue.text;
            }
            if (address[i+1] == Genivi.NAVIGATIONCORE_STREET) {
                streetValue.text=address[i+3][3][1];
                Genivi.address[Genivi.NAVIGATIONCORE_STREET]=streetValue.text;
            }
            if (address[i+1] == Genivi.NAVIGATIONCORE_HOUSENUMBER) {
                numberValue.text=address[i+3][3][1];
                Genivi.address[Genivi.NAVIGATIONCORE_HOUSENUMBER]=numberValue.text;
            }
        }

        // Manage the focus
        var focus;
        if (!countryValue.disabled)
            focus=countryValue;
        if (!cityValue.disabled)
            focus=cityValue;
        if (!streetValue.disabled)
            focus=streetValue;
        if (!numberValue.disabled)
            focus=numberValue;
        focus.takeFocus();
    }

    property Item mapmatchedpositionPositionUpdateSignal;
    function mapmatchedpositionPositionUpdate(args)
    {
        Genivi.hookSignal("mapmatchedpositionPositionUpdate");
        updateCurrentPosition();
    }

    property Item routeCalculationSuccessfulSignal;
    function routeCalculationSuccessful(args)
    { //routeHandle 1, unfullfilledPreferences 3
        Genivi.hookSignal("routeCalculationSuccessful");
        statusValue.text=Genivi.gettext("CalculatedRouteSuccess");
        Genivi.route_calculated = true;
        var res=Genivi.routing_GetRouteOverviewTimeAndDistance(dbusIf);

        var i, time = 0, distance = 0;
        for (i=0;i<res[1].length;i+=4)
        {
            if (res[1][i+1] == Genivi.NAVIGATIONCORE_TOTAL_TIME)
            {
                time = res[1][i+3][3][1];
            }
            else
            {
                if (Genivi.NAVIGATIONCORE_TOTAL_DISTANCE)
                {
                    distance = res[1][i+3][3][1];
                }
            }
        }

        distanceValue.text =Genivi.distance(distance);
        timeValue.text= Genivi.time(time);

        // Give the route handle to the FSA
        Genivi.fuelstopadvisor_SetRouteHandle(dbusIf,Genivi.g_routing_handle);
        updateStartStop();

        show_route_on_map.disabled=false;
        showRoute();
        getRouteList();
    }

    property Item routeCalculationFailedSignal;
    function routeCalculationFailed(args)
    {
        Genivi.hookSignal("routeCalculationFailed");
        //console.log("routeCalculationFailed:");
        //Genivi.dump("",args);

        statusValue.text=Genivi.gettext("CalculatedRouteFailed");
        Genivi.route_calculated = false;
        // Tell the FSA that there's no route available
        Genivi.fuelstopadvisor_ReleaseRouteHandle(dbusIf,Genivi.g_routing_handle);
    }

    property Item routeCalculationProgressUpdateSignal;
    function routeCalculationProgressUpdate(args)
    {
        Genivi.hookSignal("routeCalculationProgressUpdate");
        statusValue.text=Genivi.gettext("CalculatedRouteInProgress");
        Genivi.route_calculated = false;
    }

    property Item spellResultSignal;
    function spellResult(args)
    {//locationInputHandle 1, uniqueString 3, validCharacters 5, fullMatch 7
        Genivi.hookSignal("spellResult");
        var uniqueString=args[3];
        var validCharacters=args[5];
        if (keyboardArea.destination.text.length < uniqueString.length) {
            extraspell=uniqueString.substr(keyboardArea.destination.text.length);
            keyboardArea.destination.text=uniqueString;
        }
        keyboardArea.setactivekeys('\b'+validCharacters,true);
    }

    function connectSignals()
    {
        currentSelectionCriterionSignal=Genivi.connect_currentSelectionCriterionSignal(dbusIf,menu);
        searchStatusSignal=Genivi.connect_searchStatusSignal(dbusIf,menu);
        searchResultListSignal=Genivi.connect_searchResultListSignal(dbusIf,menu);
        contentUpdatedSignal=Genivi.connect_contentUpdatedSignal(dbusIf,menu);
        mapmatchedpositionPositionUpdateSignal=Genivi.connect_mapmatchedpositionPositionUpdateSignal(dbusIf,menu);
        routeCalculationSuccessfulSignal=Genivi.connect_routeCalculationSuccessfulSignal(dbusIf,menu);
        routeCalculationFailedSignal=Genivi.connect_routeCalculationFailedSignal(dbusIf,menu);
        routeCalculationProgressUpdateSignal=Genivi.connect_routeCalculationProgressUpdateSignal(dbusIf,menu);
        spellResultSignal=Genivi.connect_spellResultSignal(dbusIf,menu);
    }

    function disconnectSignals()
    {
        currentSelectionCriterionSignal.destroy();
        searchStatusSignal.destroy();
        searchResultListSignal.destroy();
        contentUpdatedSignal.destroy();
        mapmatchedpositionPositionUpdateSignal.destroy();
        routeCalculationSuccessfulSignal.destroy();
        routeCalculationFailedSignal.destroy();
        routeCalculationProgressUpdateSignal.destroy();
        spellResultSignal.destroy();
    }

    function getRouteList()
    {
        var res=Genivi.routing_GetRouteSegments(dbusIf,0,routeListSegments,0)
        var array=res[3];
        var model=routeArea.model;
        for (var i = 0 ; i < array.length ; i+=2) {
            var map=array[i+1];
            var mapresult=Array;
            for (var j = 0 ; j < map.length ; j+=4) {
                mapresult[map[j+1]]=map[j+3][3][1];
            }
            var text=Genivi.distance(mapresult[Genivi.NAVIGATIONCORE_DISTANCE])+" "+Genivi.time(mapresult[Genivi.NAVIGATIONCORE_TIME])+" "+mapresult[Genivi.NAVIGATIONCORE_ROAD_NAME];
            model.append({"name":text});
        }
    }

    function updateCurrentPosition()
    {
        var res=Genivi.mapmatchedposition_GetPosition(dbusIf);
        var oklat=0;
        var oklong=0;
        for (var i=0;i<res[3].length;i+=4){
            if ((res[3][i+1]== Genivi.NAVIGATIONCORE_LATITUDE) && (res[3][i+3][3][1] != 0)){
                oklat=1;
            } else {
                if ((res[3][i+1]== Genivi.NAVIGATIONCORE_LONGITUDE) && (res[3][i+3][3][1] != 0)){
                    oklong=1;
                }
            }
        }
        if ((oklat == 1) && (oklong == 1)) {vehicleLocated=true;}
        else {vehicleLocated=false;}
    }

    function updateStartStop()
    {
        var res=Genivi.guidance_GetGuidanceStatus(dbusIf);
        if (res[1] != Genivi.NAVIGATIONCORE_INACTIVE) {
            showRoute();
        } else {
            hideRoute();
        }
    }

    function spell(input)
    {
        input=extraspell+input;
        extraspell='';
        Genivi.locationinput_Spell(dbusIf,input,10);
    }

    function launchRouteCalculation()
    {
        var position,destination;

        //launch route calculation
        destination=Genivi.latlon_to_map(Genivi.data['destination']);
        position="";
        Genivi.routing_SetWaypoints(dbusIf,true,position,destination);
        Genivi.routing_CalculateRoute(dbusIf);
    }

    //------------------------------------------//
    // Management of entered location
    //------------------------------------------//
    function loadWithCountry()
    { //load the field with saved values with test if it's guidable
        if (Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY] !== "")
        {//need to test empty string
            countryValue.text=Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY];
            accept(countryValue);
            cityValue.disabled=false;
        }
        else
            Genivi.preloadMode=false; // because preload needs first a country to be launched
    }

    function reloadWithCountry()
    { // load the field with saved values
        if (Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY] !== "")
        {//need to test empty string
            countryValue.text=Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY];
            cityValue.text=Genivi.address[Genivi.NAVIGATIONCORE_CITY];
            streetValue.text=Genivi.address[Genivi.NAVIGATIONCORE_STREET];
            numberValue.text=Genivi.address[Genivi.NAVIGATIONCORE_HOUSENUMBER];
        } else {
            countryValue.text="";
            cityValue.text="";
            streetValue.text="";
            numberValue.text="";
        }
    }

    function setAddress()
    {
        //save address for next time
        Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY]=countryValue.text;
        Genivi.address[Genivi.NAVIGATIONCORE_CITY]=cityValue.text;
        Genivi.address[Genivi.NAVIGATIONCORE_STREET]=streetValue.text;
        Genivi.address[Genivi.NAVIGATIONCORE_HOUSENUMBER]=numberValue.text;
        Genivi.data['lat']=menu.lat;
        Genivi.data['lon']=menu.lon;
        Genivi.data['description']=countryValue.text;
        if (!cityValue.disabled)
            Genivi.data['description']+=' '+cityValue.text;
        if (!streetValue.disabled)
            Genivi.data['description']+=' '+streetValue.text;
        if (!numberValue.disabled)
            Genivi.data['description']+=' '+numberValue.text;
        //save entered location into the history
        Genivi.updateHistoryOfLastEnteredLocation(Genivi.data['description'],Genivi.data['lat'],Genivi.data['lon']);

        // set destination address
        Genivi.data['destination']['lat']=Genivi.data['lat'];
        Genivi.data['destination']['lon']=Genivi.data['lon'];
        Genivi.data['destination']['description']=Genivi.data['description'];
    }

    function accept(what)
    { //load text to search (search will be launched after validation of criterion)
        Genivi.locationinput_SetSelectionCriterion(dbusIf,what.criterion);
        currentTextToSearch = what.text;
    }

    function manageAddressItem()
    { //valid item and load another one if needed
        if(keyboardArea.destination === countryValue) {
            cityValue.callEntry();
            streetValue.text=""
            numberValue.text=""
            initKeyboard();
            showKeyboard();
        } else {
           if(keyboardArea.destination === cityValue) {
               streetValue.callEntry();
               numberValue.text=""
               initKeyboard();
               showKeyboard();
           } else {
               if(keyboardArea.destination === streetValue) {
                   hideKeyboard();
               }
           }
        }
    }

    //------------------------------------------//
    // Management of "keyboard" configuration
    //------------------------------------------//
    Keys.onPressed: {
        if (event.text) {
            if (event.text == '\b') {
                if (text.text.length) {
                    text.text=text.text.slice(0,-1);
                }
            } else {
                text.text+=event.text;
            }
            spell(event.text);
        }
    }

    function initKeyboard()
    {
        // when keyboard is activated, route is reset
        Genivi.route_calculated=false;
        hideRoute();
        listArea.forceActiveFocus();
        if (Genivi.entrycriterion) {
            criterion=Genivi.entrycriterion;
            Genivi.entrycriterion=0;
            Genivi.locationinput_SetSelectionCriterion(dbusIf,criterion);
        }
        extraspell='';
        if(criterion != Genivi.NAVIGATIONCORE_STREET)
        {
            spell('');
        } else { //there's a bug for street
            keyboardArea.setactivekeys('\b'+"aAuUeEbBnNrRsSiIhHfFdDcC(kK otvVgGwWmMOTjJpPlLyYzZqQ*",true);
            listArea.model.clear();
        }
    }

    function showKeyboard()
    {
        keyboardActivated = true;
        keyboardArea.visible = true;
        listArea.visible = true;
    }

    function hideKeyboard()
    {
        keyboardActivated = false;
        keyboardArea.visible = false;
        listArea.visible = false;
    }

    //------------------------------------------//
    // Management of "route" configuration
    //------------------------------------------//
    function showRoute()
    {
        guidanceTitle.visible=true;
        displayRouteTitle.visible=true;
        distanceTitle.visible=true;
        distanceValue.visible=true;
        timeTitle.visible=true;
        timeValue.visible=true;
        statusTitle.visible=true;
        statusValue.visible=true;
        show_route_on_map.visible=true;
        guidance_start.visible=true;
        guidance_stop.visible=false;
        guidance_start.disabled=false;
        guidance_stop.disabled=true;
        routeArea.visible=true;
        Genivi.route_calculated=true;
    }

    function hideRoute()
    {
        guidanceTitle.visible=false;
        displayRouteTitle.visible=false;
        distanceTitle.visible=false;
        distanceValue.visible=false;
        timeTitle.visible=false;
        timeValue.visible=false;
        statusTitle.visible=false;
        statusValue.visible=false;
        show_route_on_map.visible=false;
        guidance_start.visible=false;
        guidance_stop.visible=false;
        guidance_start.disabled=false;
        guidance_stop.disabled=true;
        routeArea.visible=false;
        Genivi.route_calculated=false;
    }


    //------------------------------------------//
    // Miscellaneous
    //------------------------------------------//
    function leave(toOtherMenu)
    {
        disconnectSignals();
        if (toOtherMenu) {
            Genivi.locationinput_handle_clear(dbusIf);
        }
        //Genivi.navigationcore_session_clear(dbusIf);
    }

    //------------------------------------------//
    // Menu elements
    //------------------------------------------//
    NavigationAppHMIBgImage {
        image:StyleSheet.navigation_app_search_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}
        id: content

        // location input menu (always visible)
        Text {
            x:StyleSheet.countryTitle[Constants.X]; y:StyleSheet.countryTitle[Constants.Y]; width:StyleSheet.countryTitle[Constants.WIDTH]; height:StyleSheet.countryTitle[Constants.HEIGHT];color:StyleSheet.countryTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.countryTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.countryTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true;
            id: countryTitle
            text: Genivi.gettext("Country");
        }
        StdButton {
            source:StyleSheet.countryKeyboard[Constants.SOURCE]; x:StyleSheet.countryKeyboard[Constants.X]; y:StyleSheet.countryKeyboard[Constants.Y]; width:StyleSheet.countryKeyboard[Constants.WIDTH]; height:StyleSheet.countryKeyboard[Constants.HEIGHT];
            id:countryKeyboard; disabled:false; next:cityKeyboard; prev:back;
            onClicked: {
                countryValue.callEntry();
                cityValue.text=""
                streetValue.text=""
                numberValue.text=""
                initKeyboard();
                showKeyboard();
            }
        }
        NavigationAppEntryField {
            x:StyleSheet.countryValue[Constants.X]; y:StyleSheet.countryValue[Constants.Y]; width: StyleSheet.countryValue[Constants.WIDTH]; height: StyleSheet.countryValue[Constants.HEIGHT];
            id: countryValue
            criterion: Genivi.NAVIGATIONCORE_COUNTRY
            globaldata: 'countryValue'
            textfocus: true
            next: cityValue
            prev: back
            onLeave:{}
        }
        Text {
            x:StyleSheet.cityTitle[Constants.X]; y:StyleSheet.cityTitle[Constants.Y]; width:StyleSheet.cityTitle[Constants.WIDTH]; height:StyleSheet.cityTitle[Constants.HEIGHT];color:StyleSheet.cityTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.cityTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.cityTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true;
            id:cityTitle
            text: Genivi.gettext("City");
        }
        StdButton {
            source:StyleSheet.cityKeyboard[Constants.SOURCE]; x:StyleSheet.cityKeyboard[Constants.X]; y:StyleSheet.cityKeyboard[Constants.Y]; width:StyleSheet.cityKeyboard[Constants.WIDTH]; height:StyleSheet.cityKeyboard[Constants.HEIGHT];
            id:cityKeyboard; disabled:false; next:streetKeyboard; prev:countryKeyboard;
            onClicked: {
                cityValue.callEntry();
                streetValue.text=""
                numberValue.text=""
                initKeyboard();
                showKeyboard();
            }
        }
        NavigationAppEntryField {
            x:StyleSheet.cityValue[Constants.X]; y:StyleSheet.cityValue[Constants.Y]; width: StyleSheet.cityValue[Constants.WIDTH]; height: StyleSheet.cityValue[Constants.HEIGHT];
            id:cityValue
            criterion: Genivi.NAVIGATIONCORE_CITY
            globaldata: 'cityValue'
            next:streetValue
            prev:countryValue
            disabled: true
            onLeave:{}
        }
        Text {
            x:StyleSheet.streetTitle[Constants.X]; y:StyleSheet.streetTitle[Constants.Y]; width:StyleSheet.streetTitle[Constants.WIDTH]; height:StyleSheet.streetTitle[Constants.HEIGHT];color:StyleSheet.streetTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.streetTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.streetTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true;
            id:streetTitle
            text: Genivi.gettext("Street");
        }
        StdButton {
            source:StyleSheet.streetKeyboard[Constants.SOURCE]; x:StyleSheet.streetKeyboard[Constants.X]; y:StyleSheet.streetKeyboard[Constants.Y]; width:StyleSheet.streetKeyboard[Constants.WIDTH]; height:StyleSheet.streetKeyboard[Constants.HEIGHT];
            id:streetKeyboard; disabled:false; next:numberKeyboard; prev:cityKeyboard;
            onClicked: {
                streetValue.callEntry();
                numberValue.text=""
                initKeyboard();
                showKeyboard();
            }
        }
        NavigationAppEntryField {
            x:StyleSheet.streetValue[Constants.X]; y:StyleSheet.streetValue[Constants.Y]; width: StyleSheet.streetValue[Constants.WIDTH]; height: StyleSheet.streetValue[Constants.HEIGHT];
            id:streetValue
            criterion: Genivi.NAVIGATIONCORE_STREET
            globaldata: 'streetValue'
            next: numberValue
            prev: cityValue
            disabled: true
            onLeave:{}
        }
        Text {
            x:StyleSheet.numberTitle[Constants.X]; y:StyleSheet.numberTitle[Constants.Y]; width:StyleSheet.numberTitle[Constants.WIDTH]; height:StyleSheet.numberTitle[Constants.HEIGHT];color:StyleSheet.numberTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.numberTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.numberTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true;
            id:numberTitle
            text: Genivi.gettext("Number");
        }
        StdButton {
            source:StyleSheet.numberKeyboard[Constants.SOURCE]; x:StyleSheet.numberKeyboard[Constants.X]; y:StyleSheet.numberKeyboard[Constants.Y]; width:StyleSheet.numberKeyboard[Constants.WIDTH]; height:StyleSheet.numberKeyboard[Constants.HEIGHT];
            id:numberKeyboard; disabled:false; next:back; prev:streetKeyboard;
            onClicked: {
                numberValue.callEntry();
                initKeyboard();
                showKeyboard();
            }
        }
        NavigationAppEntryField {
            x:StyleSheet.numberValue[Constants.X]; y:StyleSheet.numberValue[Constants.Y]; width: StyleSheet.numberValue[Constants.WIDTH]; height: StyleSheet.numberValue[Constants.HEIGHT];
            id:numberValue
            criterion: Genivi.NAVIGATIONCORE_HOUSENUMBER
            globaldata: 'numberValue'
            next: countryValue
            prev: streetValue
            disabled: true
            onLeave:{}
        }

        // route menu
        Text {
            x:StyleSheet.guidanceTitle[Constants.X]; y:StyleSheet.guidanceTitle[Constants.Y]; width:StyleSheet.guidanceTitle[Constants.WIDTH]; height:StyleSheet.guidanceTitle[Constants.HEIGHT];color:StyleSheet.guidanceTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.guidanceTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.guidanceTitle[Constants.PIXELSIZE];
            id:guidanceTitle;
            style: Text.Sunken;
            smooth: true;
            text: Genivi.gettext("Guidance");
            visible: false;
        }
        Text {
            x:StyleSheet.displayRouteTitle[Constants.X]; y:StyleSheet.displayRouteTitle[Constants.Y]; width:StyleSheet.displayRouteTitle[Constants.WIDTH]; height:StyleSheet.displayRouteTitle[Constants.HEIGHT];color:StyleSheet.displayRouteTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.displayRouteTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.displayRouteTitle[Constants.PIXELSIZE];
            id:displayRouteTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("DisplayRoute")
            visible: false;
        }
        Text {
            x:StyleSheet.distanceTitle[Constants.X]; y:StyleSheet.distanceTitle[Constants.Y]; width:StyleSheet.distanceTitle[Constants.WIDTH]; height:StyleSheet.distanceTitle[Constants.HEIGHT];color:StyleSheet.distanceTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.distanceTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.distanceTitle[Constants.PIXELSIZE];
            id:distanceTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("RouteDistance")
            visible: false;
        }
        SmartText {
            x:StyleSheet.distanceValue[Constants.X]; y:StyleSheet.distanceValue[Constants.Y]; width:StyleSheet.distanceValue[Constants.WIDTH]; height:StyleSheet.distanceValue[Constants.HEIGHT];color:StyleSheet.distanceValue[Constants.TEXTCOLOR];styleColor:StyleSheet.distanceValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.distanceValue[Constants.PIXELSIZE];
            id:distanceValue
            text: ""
            visible: false;
        }
        Text {
            x:StyleSheet.timeTitle[Constants.X]; y:StyleSheet.timeTitle[Constants.Y]; width:StyleSheet.timeTitle[Constants.WIDTH]; height:StyleSheet.timeTitle[Constants.HEIGHT];color:StyleSheet.timeTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.timeTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.timeTitle[Constants.PIXELSIZE];
            id:timeTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("RouteTime")
            visible: false;
        }
        SmartText {
            x:StyleSheet.timeValue[Constants.X]; y:StyleSheet.timeValue[Constants.Y]; width:StyleSheet.timeValue[Constants.WIDTH]; height:StyleSheet.timeValue[Constants.HEIGHT];color:StyleSheet.timeValue[Constants.TEXTCOLOR];styleColor:StyleSheet.timeValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.timeValue[Constants.PIXELSIZE];
            id:timeValue
            text: ""
            visible: false;
        }
        Text {
            x:StyleSheet.statusTitle[Constants.X]; y:StyleSheet.statusTitle[Constants.Y]; width:StyleSheet.statusTitle[Constants.WIDTH]; height:StyleSheet.statusTitle[Constants.HEIGHT];color:StyleSheet.statusTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.statusTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.statusTitle[Constants.PIXELSIZE];
            id:statusTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("StatusTitle")
            visible: false;
        }
        SmartText {
            x:StyleSheet.statusValue[Constants.X]; y:StyleSheet.statusValue[Constants.Y]; width:StyleSheet.statusValue[Constants.WIDTH]; height:StyleSheet.statusValue[Constants.HEIGHT];color:StyleSheet.statusValue[Constants.TEXTCOLOR];styleColor:StyleSheet.statusValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.statusValue[Constants.PIXELSIZE];
            id:statusValue
            text: ""
            visible: false;
        }
        StdButton {
            source:StyleSheet.show_route_on_map[Constants.SOURCE]; x:StyleSheet.show_route_on_map[Constants.X]; y:StyleSheet.show_route_on_map[Constants.Y]; width:StyleSheet.show_route_on_map[Constants.WIDTH]; height:StyleSheet.show_route_on_map[Constants.HEIGHT];
            id: show_route_on_map
             disabled:true; next:back; prev:back
            visible: false;
            onClicked: {
                disconnectSignals();
                Genivi.data["mapback"]="NavigationCalculatedRoute";
                Genivi.data["show_route_handle"]=Genivi.routing_handle(dbusIf);
                Genivi.data["zoom_route_handle"]=Genivi.routing_handle(dbusIf);
                mapMenu();
            }
        }
        StdButton {
            source:StyleSheet.guidance_start[Constants.SOURCE]; x:StyleSheet.guidance_start[Constants.X]; y:StyleSheet.guidance_start[Constants.Y]; width:StyleSheet.guidance_start[Constants.WIDTH]; height:StyleSheet.guidance_start[Constants.HEIGHT];textColor:StyleSheet.startText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.startText[Constants.PIXELSIZE];
            id:guidance_start; text: Genivi.gettext("On"); disabled:true; next:guidance_stop; prev:show_route_on_map
            visible: false;
            onClicked: {
                disconnectSignals();
                Genivi.guidance_StartGuidance(dbusIf,Genivi.routing_handle(dbusIf));
                Genivi.data["mapback"]="NavigationCalculatedRoute";
                Genivi.data["show_route_handle"]=Genivi.routing_handle(dbusIf);
                Genivi.data["show_current_position"]=true;
                mapMenu();
            }
        }
        StdButton {
            source:StyleSheet.guidance_stop[Constants.SOURCE]; x:StyleSheet.guidance_stop[Constants.X]; y:StyleSheet.guidance_stop[Constants.Y]; width:StyleSheet.guidance_stop[Constants.WIDTH]; height:StyleSheet.guidance_stop[Constants.HEIGHT];textColor:StyleSheet.stopText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.stopText[Constants.PIXELSIZE];
            id:guidance_stop;text: Genivi.gettext("Off"); disabled:true; next:show_route_on_map; prev:guidance_start
            visible: false;
            onClicked: {
                Genivi.guidance_StopGuidance(dbusIf);
                guidance_start.disabled=false;
                guidance_stop.disabled=true;
            }
        }

        // enter a location by the keyboard menu
        // keyboard
        NavigationAppKeyboard {
            x:StyleSheet.keyboardArea[Constants.X]; y:StyleSheet.keyboardArea[Constants.Y]; width:StyleSheet.keyboardArea[Constants.WIDTH]; height:StyleSheet.keyboardArea[Constants.HEIGHT];
            id: keyboardArea;
            visible: false;
            destination: countryValue; // by default
            firstLayout: "ABC";
            secondLayout: "abc";
            next: listArea;
            prev: numberKeyboard;
            onKeypress: {  spell(what); }
        }

        // route list
        Component {
            id: routeDelegate
            Text {
                property real index:number;
                width:StyleSheet.route_delegate[Constants.WIDTH]; height:StyleSheet.route_delegate[Constants.HEIGHT];color:StyleSheet.route_delegate[Constants.TEXTCOLOR];styleColor:StyleSheet.route_delegate[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.route_delegate[Constants.PIXELSIZE];
                id:routeItem;
                text: name;
                style: Text.Sunken;
                smooth: true
            }
        }

        HMIList {
            property real selectedEntry
            x:StyleSheet.routeArea[Constants.X]; y:StyleSheet.routeArea[Constants.Y]; width:StyleSheet.routeArea[Constants.WIDTH]; height:StyleSheet.routeArea[Constants.HEIGHT];
            id:routeArea
            visible: false;
            delegate: routeDelegate
            next:cancel
            prev:keyboardArea
        }

        // list of items
        Component {
            id: listDelegate
            Text {
                property real index:number;
                width:StyleSheet.list_delegate[Constants.WIDTH]; height:StyleSheet.list_delegate[Constants.HEIGHT];color:StyleSheet.list_delegate[Constants.TEXTCOLOR];styleColor:StyleSheet.list_delegate[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.list_delegate[Constants.PIXELSIZE];
                id:textItem;
                text: name;
                style: Text.Sunken;
                smooth: true
            }
        }

        NavigationAppHMIList {
            property real selectedEntry
            x:StyleSheet.listArea[Constants.X]; y:StyleSheet.listArea[Constants.Y]; width:StyleSheet.listArea[Constants.WIDTH]; height:StyleSheet.listArea[Constants.HEIGHT];
            id:listArea
            visible: false;
            delegate: listDelegate
            next:cancel
            prev:keyboardArea
            onSelected:{
                Genivi.entryselectedentry=what.index;
                // Set value of corresponding field and hide keyboard and list
                Genivi.locationinput_SelectEntry(dbusIf,Genivi.entryselectedentry-1);
                manageAddressItem();
            }
        }

        // bottom banner
        StdButton {
            source:StyleSheet.calculate_curr[Constants.SOURCE]; x:StyleSheet.calculate_curr[Constants.X]; y:StyleSheet.calculate_curr[Constants.Y]; width:StyleSheet.calculate_curr[Constants.WIDTH]; height:StyleSheet.calculate_curr[Constants.HEIGHT];textColor:StyleSheet.calculate_currText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.calculate_currText[Constants.PIXELSIZE];
            id:calculate_curr; text: Genivi.gettext("GoTo");
            onClicked: {
                setAddress();
                launchRouteCalculation();
            }
            disabled:!(vehicleLocated && destinationValid && !(keyboardActivated));
            next:back; prev:numberKeyboard
        }
        StdButton {
            source:StyleSheet.cancel[Constants.SOURCE]; x:StyleSheet.cancel[Constants.X]; y:StyleSheet.cancel[Constants.Y]; width:StyleSheet.cancel[Constants.WIDTH]; height:StyleSheet.cancel[Constants.HEIGHT];textColor:StyleSheet.cancelText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.cancelText[Constants.PIXELSIZE];
            id:cancel; text: Genivi.gettext("Cancel");
            disabled: !(keyboardActivated);
            onClicked: {
                Genivi.entrycancel=true;
                Genivi.preloadMode=true;
                hideKeyboard();
                reloadWithCountry();
            }
            next:settings; prev:calculate_curr;
        }
        StdButton {
            source:StyleSheet.settings[Constants.SOURCE]; x:StyleSheet.settings[Constants.X]; y:StyleSheet.settings[Constants.Y]; width:StyleSheet.settings[Constants.WIDTH]; height:StyleSheet.settings[Constants.HEIGHT];
            id:settings;  next:back; prev:calculate_curr;
            disabled: keyboardActivated;
            onClicked: {
                Genivi.preloadMode=true; //for the next call of this menu
                entryMenu("NavigationAppSettings",menu);
            }
        }
        StdButton {
            source:StyleSheet.poi[Constants.SOURCE]; x:StyleSheet.poi[Constants.X]; y:StyleSheet.poi[Constants.Y]; width:StyleSheet.poi[Constants.WIDTH]; height:StyleSheet.poi[Constants.HEIGHT];
            id:poi;  next:back; prev:calculate_curr;
            disabled: keyboardActivated;
            onClicked: {
                entryMenu("NavigationAppPOI",menu);
            }
        }
        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back");
            disabled: keyboardActivated; next:streetValue; prev:calculate_curr;
            onClicked: {
                disconnectSignals();
                Genivi.locationinput_handle_clear(dbusIf); //clear the handle
                leaveMenu();
            }
        }

    }

    Component.onCompleted: {
        connectSignals();

        hideKeyboard(); // no keyboard by default

        listArea.model.clear(); // clean lists
        routeArea.model.clear();

        if (Genivi.route_calculated) {
            launchRouteCalculation(); //relaunch route calculation to refresh data
            showRoute();
        }
        else {
            hideRoute();
        }

        var res=Genivi.locationinput_handle(dbusIf); //get an handle for the location input

        // Preload address if activated
        if (Genivi.preloadMode==true)
        {
            loadWithCountry();
        }

        updateCurrentPosition();
    }
}
