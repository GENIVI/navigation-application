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
    property Item currentSelectionCriterionSignal;
    property Item searchStatusSignal;
    property Item searchResultListSignal;
    property Item contentUpdatedSignal;
    property Item mapmatchedpositionPositionUpdateSignal;
    property Item routeCalculationSuccessfulSignal;
    property Item routeCalculationFailedSignal;
    property Item routeCalculationProgressUpdateSignal;
    property string routeText:" "
    property real lat
    property real lon
    property bool vehicleLocated

    function loadWithCountry()
    {
        //load the field with saved values
        if (Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY] !== "")
        {//need to test empty string
            countryValue.text=Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY];
            accept(countryValue);
            cityValue.disabled=false;
        }
        else
            Genivi.preloadMode=false;
    }

    function setLocation()
    {
        Genivi.route_calculated = false; //position or destination changed, so needs to calculate a new route
        locationValue.text=Genivi.data['description'];
        positionValue.text=(Genivi.data['position'] ? Genivi.data['position']['description']:"");
        destinationValue.text=(Genivi.data['destination'] ? Genivi.data['destination']['description']:"");
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
        if ((oklat == 1) && (oklong == 1) && Genivi.data['destination']) {
             vehicleLocated=true;
         } else {
             vehicleLocated=false;
         }
    }

    function mapmatchedpositionPositionUpdate(args)
    {
        Genivi.hookSignal("mapmatchedpositionPositionUpdate");
        updateCurrentPosition();
    }

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

    function routeCalculationProgressUpdate(args)
    {
        Genivi.hookSignal("routeCalculationProgressUpdate");
        statusValue.text=Genivi.gettext("CalculatedRouteInProgress");
        Genivi.route_calculated = false;
    }

    function updateStartStop()
    {
        var res=Genivi.guidance_GetGuidanceStatus(dbusIf);
        if (res[1] != Genivi.NAVIGATIONCORE_INACTIVE) {
            guidance_start.disabled=true;
            guidance_stop.disabled=false;
        } else {
            guidance_start.disabled=false;
            guidance_stop.disabled=true;
        }
    }

    function routeCalculationSuccessful(args)
    { //routeHandle 1, unfullfilledPreferences 3
        Genivi.hookSignal("routeCalculationSuccessful");
        show_route_on_map.disabled=false;
        show_route_in_list.disabled=false;
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
    }

    function currentSelectionCriterion(args)
    {// locationInputHandle 1, selectionCriterion 3
        Genivi.hookSignal("currentSelectionCriterion");
        var selectionCriterion=args[3];
        Genivi.entrycriterion = selectionCriterion;
    }

    function searchStatus(args)
    { //locationInputHandle 1, statusValue 3
        Genivi.hookSignal("searchStatus");
        var statusValue=args[3];
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

    function searchResultList(args)
    {
        Genivi.hookSignal("searchResultList");
    }

    function contentUpdated(args)
    { //locationInputHandle 1, guidable 3, availableSelectionCriteria 5, address 7
        Genivi.hookSignal("contentUpdated");
        // Check if the destination is guidable
        var guidable=args[3];
        if (guidable) {
            calculate_curr.disabled=false;
        }
        else
        {
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
        for (var i=0 ; i < address.length ; i+=4) {
            if (address[i+1] == Genivi.NAVIGATIONCORE_LATITUDE) lat=address[i+3][3][1];
            if (address[i+1] == Genivi.NAVIGATIONCORE_LONGITUDE) lon=address[i+3][3][1];
            if (address[i+1] == Genivi.NAVIGATIONCORE_COUNTRY) countryValue.text=address[i+3][3][1];
            if (address[i+1] == Genivi.NAVIGATIONCORE_CITY) cityValue.text=address[i+3][3][1];
            if (address[i+1] == Genivi.NAVIGATIONCORE_STREET) streetValue.text=address[i+3][3][1];
            if (address[i+1] == Genivi.NAVIGATIONCORE_HOUSENUMBER) numberValue.text=address[i+3][3][1];
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
    }

    function accept(what)
    {
        calculate_curr.disabled=true;
        Genivi.locationinput_SetSelectionCriterion(dbusIf,what.criterion);
        Genivi.locationinput_Search(dbusIf,what.text,10);
    }

    function leave(toOtherMenu)
    {
        disconnectSignals();
        if (toOtherMenu) {
            Genivi.locationinput_handle_clear(dbusIf);
        }
        //Genivi.navigationcore_session_clear(dbusIf);
    }

    DBusIf {
        id: dbusIf
    }

    NavigationAppHMIBgImage {
        image:StyleSheet.navigation_app_search_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}
        id: content

        // location input menu
        Text {
            x:StyleSheet.countryTitle[Constants.X]; y:StyleSheet.countryTitle[Constants.Y]; width:StyleSheet.countryTitle[Constants.WIDTH]; height:StyleSheet.countryTitle[Constants.HEIGHT];color:StyleSheet.countryTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.countryTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.countryTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true;
            id: countryTitle
            text: Genivi.gettext("Country");
        }
        StdButton {
            source:StyleSheet.countryKeyboard[Constants.SOURCE]; x:StyleSheet.countryKeyboard[Constants.X]; y:StyleSheet.countryKeyboard[Constants.Y]; width:StyleSheet.countryKeyboard[Constants.WIDTH]; height:StyleSheet.countryKeyboard[Constants.HEIGHT];
            id:countryKeyboard; disabled:false; next:cityKeyboard; prev:back; explode:false;
            onClicked: {
                countryValue.callEntry()
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
            onLeave:{menu.leave(0)}
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
            id:cityKeyboard; disabled:false; next:streetKeyboard; prev:countryKeyboard; explode:false;
            onClicked: {
                cityValue.callEntry()
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
            onLeave:{menu.leave(0)}
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
            id:streetKeyboard; disabled:false; next:numberKeyboard; prev:cityKeyboard; explode:false;
            onClicked: {
                streetValue.callEntry()
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
            onLeave:{menu.leave(0)}
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
            id:numberKeyboard; disabled:false; next:back; prev:streetKeyboard; explode:false;
            onClicked: {
                numberValue.callEntry()
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
            onLeave:{menu.leave(0)}
        }

        // route menu
        Text {
            x:StyleSheet.guidanceTitle[Constants.X]; y:StyleSheet.guidanceTitle[Constants.Y]; width:StyleSheet.guidanceTitle[Constants.WIDTH]; height:StyleSheet.guidanceTitle[Constants.HEIGHT];color:StyleSheet.guidanceTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.guidanceTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.guidanceTitle[Constants.PIXELSIZE];
            id:guidanceTitle;
            style: Text.Sunken;
            smooth: true;
            text: Genivi.gettext("Guidance");
            visible: (Genivi.route_calculated);
        }
        Text {
            x:StyleSheet.displayRouteTitle[Constants.X]; y:StyleSheet.displayRouteTitle[Constants.Y]; width:StyleSheet.displayRouteTitle[Constants.WIDTH]; height:StyleSheet.displayRouteTitle[Constants.HEIGHT];color:StyleSheet.displayRouteTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.displayRouteTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.displayRouteTitle[Constants.PIXELSIZE];
            id:displayRouteTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("DisplayRoute")
            visible: (Genivi.route_calculated);
        }
        Text {
            x:StyleSheet.distanceTitle[Constants.X]; y:StyleSheet.distanceTitle[Constants.Y]; width:StyleSheet.distanceTitle[Constants.WIDTH]; height:StyleSheet.distanceTitle[Constants.HEIGHT];color:StyleSheet.distanceTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.distanceTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.distanceTitle[Constants.PIXELSIZE];
            id:distanceTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("RouteDistance")
            visible: (Genivi.route_calculated);
        }
        SmartText {
            x:StyleSheet.distanceValue[Constants.X]; y:StyleSheet.distanceValue[Constants.Y]; width:StyleSheet.distanceValue[Constants.WIDTH]; height:StyleSheet.distanceValue[Constants.HEIGHT];color:StyleSheet.distanceValue[Constants.TEXTCOLOR];styleColor:StyleSheet.distanceValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.distanceValue[Constants.PIXELSIZE];
            id:distanceValue
            text: ""
            visible: (Genivi.route_calculated);
        }
        Text {
            x:StyleSheet.timeTitle[Constants.X]; y:StyleSheet.timeTitle[Constants.Y]; width:StyleSheet.timeTitle[Constants.WIDTH]; height:StyleSheet.timeTitle[Constants.HEIGHT];color:StyleSheet.timeTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.timeTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.timeTitle[Constants.PIXELSIZE];
            id:timeTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("RouteTime")
            visible: (Genivi.route_calculated);
        }
        SmartText {
            x:StyleSheet.timeValue[Constants.X]; y:StyleSheet.timeValue[Constants.Y]; width:StyleSheet.timeValue[Constants.WIDTH]; height:StyleSheet.timeValue[Constants.HEIGHT];color:StyleSheet.timeValue[Constants.TEXTCOLOR];styleColor:StyleSheet.timeValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.timeValue[Constants.PIXELSIZE];
            id:timeValue
            text: ""
            visible: (Genivi.route_calculated);
        }
        Text {
            x:StyleSheet.statusTitle[Constants.X]; y:StyleSheet.statusTitle[Constants.Y]; width:StyleSheet.statusTitle[Constants.WIDTH]; height:StyleSheet.statusTitle[Constants.HEIGHT];color:StyleSheet.statusTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.statusTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.statusTitle[Constants.PIXELSIZE];
            id:statusTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("StatusTitle")
            visible: (Genivi.route_calculated);
        }
        SmartText {
            x:StyleSheet.statusValue[Constants.X]; y:StyleSheet.statusValue[Constants.Y]; width:StyleSheet.statusValue[Constants.WIDTH]; height:StyleSheet.statusValue[Constants.HEIGHT];color:StyleSheet.statusValue[Constants.TEXTCOLOR];styleColor:StyleSheet.statusValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.statusValue[Constants.PIXELSIZE];
            id:statusValue
            text: ""
            visible: (Genivi.route_calculated);
        }

        StdButton {
            source:StyleSheet.show_route_on_map[Constants.SOURCE]; x:StyleSheet.show_route_on_map[Constants.X]; y:StyleSheet.show_route_on_map[Constants.Y]; width:StyleSheet.show_route_on_map[Constants.WIDTH]; height:StyleSheet.show_route_on_map[Constants.HEIGHT];
            id: show_route_on_map
            explode:false; disabled:true; next:show_route_in_list; prev:back
            visible: (Genivi.route_calculated);
            onClicked: {
                disconnectSignals();
                Genivi.data["mapback"]="NavigationCalculatedRoute";
                Genivi.data["show_route_handle"]=Genivi.routing_handle(dbusIf);
                Genivi.data["zoom_route_handle"]=Genivi.routing_handle(dbusIf);
                mapMenu();
            }
        }
        StdButton {
            source:StyleSheet.show_route_in_list[Constants.SOURCE]; x:StyleSheet.show_route_in_list[Constants.X]; y:StyleSheet.show_route_in_list[Constants.Y]; width:StyleSheet.show_route_in_list[Constants.WIDTH]; height:StyleSheet.show_route_in_list[Constants.HEIGHT];
            id:show_route_in_list;
            explode:false; disabled:true; next:back; prev:show_route_on_map;
            visible: (Genivi.route_calculated);
            onClicked: {
                entryMenu("NavigationRouteDescription",menu);
            }
        }

        StdButton {
            source:StyleSheet.guidance_start[Constants.SOURCE]; x:StyleSheet.guidance_start[Constants.X]; y:StyleSheet.guidance_start[Constants.Y]; width:StyleSheet.guidance_start[Constants.WIDTH]; height:StyleSheet.guidance_start[Constants.HEIGHT];textColor:StyleSheet.startText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.startText[Constants.PIXELSIZE];
            id:guidance_start; text: Genivi.gettext("On");explode:false; disabled:true; next:guidance_stop; prev:show_route_on_map
            visible: (Genivi.route_calculated);
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
            id:guidance_stop;text: Genivi.gettext("Off");explode:false; disabled:true; next:show_route_on_map; prev:guidance_start
            visible: (Genivi.route_calculated);
            onClicked: {
                Genivi.guidance_StopGuidance(dbusIf);
                guidance_start.disabled=false;
                guidance_stop.disabled=true;
            }
        }

        StdButton {
            source:StyleSheet.calculate_curr[Constants.SOURCE]; x:StyleSheet.calculate_curr[Constants.X]; y:StyleSheet.calculate_curr[Constants.Y]; width:StyleSheet.calculate_curr[Constants.WIDTH]; height:StyleSheet.calculate_curr[Constants.HEIGHT];textColor:StyleSheet.calculate_currText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.calculate_currText[Constants.PIXELSIZE];
            id:calculate_curr; text: Genivi.gettext("GoTo"); explode:false;
            visible: (vehicleLocated);
            onClicked: {
                var position,destination;
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

                //launch route calculation
                destination=Genivi.latlon_to_map(Genivi.data['destination']);
                position="";
                Genivi.routing_SetWaypoints(dbusIf,true,position,destination);
                Genivi.data['calculate_route']=true;
                disconnectSignals();
                Genivi.data['lat']='';
                Genivi.data['lon']='';
            }
            disabled:true; next:back; prev:numberKeyboard
        }

        StdButton {
            source:StyleSheet.settings[Constants.SOURCE]; x:StyleSheet.settings[Constants.X]; y:StyleSheet.settings[Constants.Y]; width:StyleSheet.settings[Constants.WIDTH]; height:StyleSheet.settings[Constants.HEIGHT];
            id:settings; explode:false; next:back; prev:calculate_curr; onClicked: {
                entryMenu("NavigationAppSettings",menu);
            }
        }

        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back");
            onClicked: {
                disconnectSignals();
                Genivi.data['lat']='';
                Genivi.data['lon']='';
                leaveMenu();
            }
            disabled:false; next:streetValue; prev:calculate_curr;
        }

    }
    Component.onCompleted: {
        connectSignals();

        vehicleLocated = false;

        //Test if the navigation server is connected
        var res=Genivi.navigationcore_session_GetVersion(dbusIf);
        if (res[0] != "error") {
            res=Genivi.navigationcore_session(dbusIf);
            res=Genivi.locationinput_handle(dbusIf);
        } else {
            Genivi.dump("",res);
        }
        // Preload address if activated
        if (Genivi.entryselectedentry) {
            Genivi.locationinput_SelectEntry(dbusIf,Genivi.entryselectedentry-1);
        }
        if (Genivi.entrydest == 'countryValue')
        {
            accept(countryValue);
        }
        if (Genivi.entrydest == 'cityValue')
        {
            accept(cityValue);
        }
        if (Genivi.entrydest == 'streetValue')
        {
            accept(streetValue);
        }
        if (Genivi.entrydest == 'numberValue')
        {
            accept(numberValue);
        }
        Genivi.entrydest=null;

        if (Genivi.preloadMode==true)
        {
            loadWithCountry();
        }

        updateCurrentPosition();
/*
        // Check is route is active
        if (Genivi.data["calculate_route"]) {
            Genivi.routing_CalculateRoute(dbusIf);
            delete(Genivi.data["calculate_route"]);
        } else {
            routeCalculationSuccessful("dummy");
        }
        updateStartStop();*/
    }
}
