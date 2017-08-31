/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file POI.qml
*
* \brief This file is part of the FSA hmi.
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
import QtQuick 2.1 
import "Core"
import "Core/genivi.js" as Genivi;
import "../style-sheets/style-constants.js" as Constants;
import "../style-sheets/NavigationAppPOI-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0
import lbs.plugin.dltif 1.0

NavigationAppHMIMenu {
	id: menu
    property string pagefile:"NavigationAppPOI"
    property string all_categories: "all categories"
    property string poiCategoryName
    property bool vehicleLocated: false

    DLTIf {
        id:dltIf;
        name: pagefile
    }

    //------------------------------------------//
    // Management of the DBus exchanges
    //------------------------------------------//
    DBusIf {
    	id: dbusIf
    }

    property Item mapmatchedpositionPositionUpdateSignal;
    function mapmatchedpositionPositionUpdate(args)
    {
        Genivi.hookSignal(dltIf,"mapmatchedpositionPositionUpdate");
        if(!Genivi.showroom) {
            updateCurrentPosition();
        }
    }

    function connectSignals()
    {
        mapmatchedpositionPositionUpdateSignal=Genivi.connect_mapmatchedpositionPositionUpdateSignal(dbusIf,menu);
    }

    function disconnectSignals()
    {
        mapmatchedpositionPositionUpdateSignal.destroy();
    }

    function updateCurrentPosition()
    {
        var res=Genivi.mapmatchedposition_GetPosition(dbusIf,dltIf);
        var oklat=0;
        var oklong=0;
        for (var i=0;i<res[3].length;i+=4){
            if ((res[3][i+1]== Genivi.NAVIGATIONCORE_LATITUDE) && (res[3][i+3][3][1] != 0)){
                oklat=1;
                Genivi.data['current_position']['lat']=res[3][i+3][3][1];
            } else {
                if ((res[3][i+1]== Genivi.NAVIGATIONCORE_LONGITUDE) && (res[3][i+3][3][1] != 0)){
                    oklong=1;
                    Genivi.data['current_position']['lon']=res[3][i+3][3][1];
                } else {
                    if (res[3][i+1]== Genivi.NAVIGATIONCORE_ALTITUDE){
                        Genivi.data['current_position']['alt']=res[3][i+3][3][1];
                    }
                }
            }
        }
        if ((oklat == 1) && (oklong == 1)) {vehicleLocated=true;}
        else {vehicleLocated=false;}
    }

    function displayCategoryList()
    {
        var model=view.model;
        for(var i=0;i<Genivi.categoriesIdNameList.length;i+=2)
        {
            if(Genivi.categoriesIdNameList[i+1][3]!==all_categories)
                model.append({"name":Genivi.categoriesIdNameList[i+1][3],"number":i/2});
        }
        categoryValue.text=model.get(0).name; // to be clarified
    }

    function searchPois()
    {
        var model=view.model;
        var ids=[];
        var latitude=0;
        var longitude=0;

        Genivi.setDestinationDefined(dltIf,false);

        if(Genivi.showroom) {
            latitude=Genivi.data['default_position']['lat'];
            longitude=Genivi.data['default_position']['lon'];
        }else{
            latitude=Genivi.data['current_position']['lat'];
            longitude=Genivi.data['current_position']['lon'];
        }

        if (!latitude && !longitude) {
            model.clear();
            model.append({"name":"No position available"});
            return;
        }
        var categoriesAndRadius=[];
        var categoriesAndRadiusList=[];
        categoriesAndRadius[0]=Genivi.category_id;
        categoriesAndRadius[1]=Genivi.radius;
        categoriesAndRadiusList.push(categoriesAndRadius);

        var res_poi=Genivi.poisearch_CreatePoiSearchHandle(dbusIf,dltIf)
        Genivi.g_poisearch_handle[1]=res_poi[1];
        Genivi.poisearch_SetCenter(dbusIf,dltIf,latitude,longitude,0);
        Genivi.poisearch_SetCategories(dbusIf,dltIf,categoriesAndRadiusList);
        Genivi.poisearch_StartPoiSearch(dbusIf,dltIf,keyboardArea.destination.text,Genivi.POISERVICE_SORT_BY_DISTANCE);
        var attributeList=[];
        attributeList[0]=0;
        var res=Genivi.poisearch_RequestResultList(dbusIf,dltIf,Genivi.offset,Genivi.maxResultListSize,attributeList);
        searchResultNumber.visible=true;
        if(res[3]<Genivi.maxResultListSize)
            searchResultNumber.text=res[3];
        else searchResultNumber.text=">"+Genivi.maxResultListSize;
        model.clear();
        if(res[3]===0)
        {
            //no match
            return
        }

        var res_win=res[5];
        var i;
        for (i = 0 ; i < res_win.length ; i+=2) {
            var id=res_win[i+1][1];
            ids.push(id);
            Genivi.poi_data[id]=[];
            Genivi.poi_data[id].id=id;
            Genivi.poi_data[id].category=Genivi.category_id;
            Genivi.poi_data[id].distance=res_win[i+1][3];
        }
        var details=Genivi.poisearch_GetPoiDetails(dbusIf,dltIf,ids);
        for (i = 0 ; i < details[1].length ; i+=2) {
            var poi_details=details[1][i+1];
            id=poi_details[1][1];
            Genivi.poi_data[id].name=poi_details[1][3];
            Genivi.poi_data[id].lat=poi_details[1][5][1];
            Genivi.poi_data[id].lon=poi_details[1][5][3];
        }
        for (i = 0 ; i < ids.length ; i+=1) {
            id=ids[i];
            var poi_data=Genivi.poi_data[id];
            if((poi_data.name !== "") && (poi_data.name !== "?") ){ //filter empty and unknown names
                model.append({"name":poi_data.name,"number":id});
            }
        }
        if(res[3]===1){
            Genivi.setDestinationDefined(dltIf,true);
            selectPoi(0);
        }
    }

    function selectPoi(index)
    {
        Genivi.poi_id=index;
        var poi_data=Genivi.poi_data[index];
        poiName.text=poi_data.name;
        poiName.visible=true;
        selectedValue.text="Lat: "+poi_data.lat.toFixed(4)+"\nLon: "+poi_data.lon.toFixed(4)+"\nDist: "+poi_data.distance+" m";
        searchResultNumber.visible=false;
        selectedValueTitle.visible=true;
        select_reroute.disabled=false;
        select_display_on_map.disabled=false;
    }

    function clearSearch()
    {
        Genivi.poi_data=[];
        poiName.text="";
        poiName.visible=false;
        selectedValue.text="Lat:\nLon:\nDist:\n";
        searchResultNumber.visible=false;
        selectedValueTitle.visible=false;
        select_reroute.disabled=true;
        select_display_on_map.disabled=true;
        if(Genivi.g_poisearch_handle[1]){
            Genivi.poisearch_DeletePoiSearchHandle(dbusIf,dltIf)
            Genivi.g_poisearch_handle[1]=0;
        }
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

    //------------------------------------------//
    // Management of "keyboard" configuration
    //------------------------------------------//
    Keys.onPressed: {
        if (event.text) {
            if (event.text === '\b') {
                if (text.text.length) {
                    text.text=text.text.slice(0,-1);
                }
            } else {
                text.text+=event.text;
            }
            spell(event.text);
        }
    }

    function spell(input)
    {
        keyboardArea.destination.text = keyboardArea.destination.text+input;
    }

    NavigationAppHMIBgImage {
        image:StyleSheet.navigation_app_poi_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight }

        StdButton {
            source:StyleSheet.categoryKeyboard[Constants.SOURCE]; x:StyleSheet.categoryKeyboard[Constants.X]; y:StyleSheet.categoryKeyboard[Constants.Y]; width:StyleSheet.categoryKeyboard[Constants.WIDTH]; height:StyleSheet.categoryKeyboard[Constants.HEIGHT];
            id:categoryKeyboard; disabled:false; next:poiKeyboard; prev:back;
            onClicked: {
                keyboardArea.destination=categoryValue;
                Genivi.poi_id=null; //clear current selected poi
                poiValue.text="";
                selectedValue.text="Lat:\nLon:\nDist:\n";
                poiName.visible=false;
                selectedValueTitle.visible=false;
                searchResultNumber.visible=false;
                categoryValue.text=poiCategoryName;
                poiFrame.visible=false;
                categoryFrame.visible=true;
                view.model.clear();
                displayCategoryList();
            }
        }
        Image {
            source:StyleSheet.categoryFrame[Constants.SOURCE]; x:StyleSheet.categoryFrame[Constants.X]; y:StyleSheet.categoryFrame[Constants.Y]; width:StyleSheet.categoryFrame[Constants.WIDTH]; height:StyleSheet.categoryFrame[Constants.HEIGHT];
            id:categoryFrame;
            visible:false;
        }
        NavigationAppEntryField {
            x:StyleSheet.categoryValue[Constants.X]; y:StyleSheet.categoryValue[Constants.Y]; width: StyleSheet.categoryValue[Constants.WIDTH]; height: StyleSheet.categoryValue[Constants.HEIGHT];
            id: categoryValue
            globaldata: 'categoryValue'
            textfocus: true
            onLeave:{}
        }
        StdButton {
            source:StyleSheet.poiKeyboard[Constants.SOURCE]; x:StyleSheet.poiKeyboard[Constants.X]; y:StyleSheet.poiKeyboard[Constants.Y]; width:StyleSheet.poiKeyboard[Constants.WIDTH]; height:StyleSheet.poiKeyboard[Constants.HEIGHT];
            id:poiKeyboard; disabled:false;
            onClicked: {
                keyboardArea.destination=poiValue;
                poiValue.text="";
                categoryValue.text=poiCategoryName;
                poiFrame.visible=true;
                categoryFrame.visible=false;
                view.model.clear();
            }
        }
        Image {
            source:StyleSheet.poiFrame[Constants.SOURCE]; x:StyleSheet.poiFrame[Constants.X]; y:StyleSheet.poiFrame[Constants.Y]; width:StyleSheet.poiFrame[Constants.WIDTH]; height:StyleSheet.poiFrame[Constants.HEIGHT];
            id:poiFrame;
            visible:false;
        }
        NavigationAppEntryField {
            x:StyleSheet.poiValue[Constants.X]; y:StyleSheet.poiValue[Constants.Y]; width: StyleSheet.poiValue[Constants.WIDTH]; height: StyleSheet.poiValue[Constants.HEIGHT];
            id: poiValue
            globaldata: 'poiValue'
            textfocus: true
            onLeave:{}
        }

        SmartText {
            x:StyleSheet.poiName[Constants.X]; y:StyleSheet.poiName[Constants.Y]; width:StyleSheet.poiName[Constants.WIDTH]; height:StyleSheet.poiName[Constants.HEIGHT];color:StyleSheet.poiName[Constants.TEXTCOLOR];styleColor:StyleSheet.poiName[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.poiName[Constants.PIXELSIZE];
            id:poiName;
            visible: false
            style: Text.Sunken;
            smooth: true
            text: ""
        }
        Text {
            x:StyleSheet.selectedValueTitle[Constants.X]; y:StyleSheet.selectedValueTitle[Constants.Y]; width:StyleSheet.selectedValueTitle[Constants.WIDTH]; height:StyleSheet.selectedValueTitle[Constants.HEIGHT];color:StyleSheet.selectedValueTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.selectedValueTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.selectedValueTitle[Constants.PIXELSIZE];
            id:selectedValueTitle;
            visible: false
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Selected")
	   	}
		Text {
            x:StyleSheet.selectedValue[Constants.X]; y:StyleSheet.selectedValue[Constants.Y]; width:StyleSheet.selectedValue[Constants.WIDTH]; height:StyleSheet.selectedValue[Constants.HEIGHT];color:StyleSheet.selectedValue[Constants.TEXTCOLOR];styleColor:StyleSheet.selectedValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.selectedValue[Constants.PIXELSIZE];
            id:selectedValue
            style: Text.Sunken;
            smooth: true
            clip: true
            text: "Lat:\nLon:\nDist:\n"
        }
        Text {
            x:StyleSheet.searchResultNumber[Constants.X]; y:StyleSheet.searchResultNumber[Constants.Y]; width:StyleSheet.searchResultNumber[Constants.WIDTH]; height:StyleSheet.searchResultNumber[Constants.HEIGHT];color:StyleSheet.searchResultNumber[Constants.TEXTCOLOR];styleColor:StyleSheet.searchResultNumber[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.searchResultNumber[Constants.PIXELSIZE];
            id:searchResultNumber
            style: Text.Sunken;
            smooth: true
            clip: true
            text: ""
        }
        Component {
            id: searchResultList
            Text {
                width:StyleSheet.searchResultValue[Constants.WIDTH]; height:StyleSheet.searchResultValue[Constants.HEIGHT];color:StyleSheet.searchResultValue[Constants.TEXTCOLOR];styleColor:StyleSheet.searchResultValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.searchResultValue[Constants.PIXELSIZE];
                id:searchResultValue;
				property real index:number;
				text: name;
				style: Text.Sunken;
				smooth: true
			}
		}
        NavigationAppHMIList {
            x:StyleSheet.searchResultList[Constants.X]; y:StyleSheet.searchResultList[Constants.Y]; width:StyleSheet.searchResultList[Constants.WIDTH]; height:StyleSheet.searchResultList[Constants.HEIGHT];
			property real selectedEntry
			id:view
            delegate: searchResultList
			onSelected:{
                if(keyboardArea.destination===poiValue)
                {
                    if (what) {
                        Genivi.setDestinationDefined(dltIf,true);
                        selectPoi(what.index);
                    } else {
                        Genivi.setDestinationDefined(dltIf,false);
                        Genivi.poi_id=null;
                        poiName.visible=false;
                        selectedValue.text="Lat:\nLon:\nDist:\n";
                        searchResultNumber.visible=false;
                        selectedValueTitle.visible=false;
                        select_reroute.disabled=true;
                        select_display_on_map.disabled=true;
                        keyboardArea.destination.text=""
                    }
                } else {
                   if (what) {
                       poiCategoryName=Genivi.categoriesIdNameList[((what.index)*2)+1][3];
                       Genivi.category_id=Genivi.categoriesIdNameList[((what.index)*2)+1][1];
                       keyboardArea.destination.text=poiCategoryName;
                       keyboardArea.destination=poiValue;
                       poiValue.text="";
                       categoryValue.text=poiCategoryName;
                       poiFrame.visible=true;
                       categoryFrame.visible=false;
                       view.model.clear();
                       //launch a search on the selected category
                       clearSearch();
                       searchPois();
                   } else {
                       keyboardArea.destination.text=""
                   }
                }

			}
		}       

        NavigationAppKeyboard {
            x:StyleSheet.keyboardArea[Constants.X]; y:StyleSheet.keyboardArea[Constants.Y]; width:StyleSheet.keyboardArea[Constants.WIDTH]; height:StyleSheet.keyboardArea[Constants.HEIGHT];
            id: keyboardArea;
            visible: true;
            destination: poiValue;
            firstLayout: Genivi.kbdFirstLayout;
            secondLayout: Genivi.kbdSecondLayout;
            onKeypress: {
                //launch a search on the selected category
                clearSearch();
                searchPois();
            }
        }

        StdButton {
            source:StyleSheet.location_input[Constants.SOURCE]; x:StyleSheet.location_input[Constants.X]; y:StyleSheet.location_input[Constants.Y]; width:StyleSheet.location_input[Constants.WIDTH]; height:StyleSheet.location_input[Constants.HEIGHT];
            id:location_input;
            onClicked: {
                disconnectSignals();
                exitRoute();
                //the location is entered by address
                Genivi.setLocationInputActivated(dltIf,true);
                Genivi.preloadMode=true;
                pageOpen(dltIf,"NavigationAppSearch");
            }
        }
		StdButton { 
            source:StyleSheet.select_reroute[Constants.SOURCE]; x:StyleSheet.select_reroute[Constants.X]; y:StyleSheet.select_reroute[Constants.Y]; width:StyleSheet.select_reroute[Constants.WIDTH]; height:StyleSheet.select_reroute[Constants.HEIGHT];
            id:select_reroute;            
            disabled:true;
			onClicked: {
                disconnectSignals();
                Genivi.data['destination']=Genivi.poi_data[Genivi.poi_id];
                Genivi.setRerouteRequested(dltIf,true);
                //create a route
                var res4=Genivi.routing_CreateRoute(dbusIf,dltIf);
                Genivi.g_routing_handle[1]=res4[3];
                pageOpen(dltIf,"NavigationAppSearch");
			}
		}
        StdButton {
            source:StyleSheet.select_display_on_map[Constants.SOURCE]; x:StyleSheet.select_display_on_map[Constants.X]; y:StyleSheet.select_display_on_map[Constants.Y]; width:StyleSheet.select_display_on_map[Constants.WIDTH]; height:StyleSheet.select_display_on_map[Constants.HEIGHT];
            id:select_display_on_map;           
            disabled:(!(Genivi.destination_defined) || (Genivi.route_calculated));
			onClicked: {
                disconnectSignals();
                var poi_data=Genivi.poi_data[Genivi.poi_id];
                Genivi.data['position']['lat']=poi_data.lat;
                Genivi.data['position']['lon']=poi_data.lon;
                Genivi.data['display_on_map']='show_position';
                Genivi.hookMessage(dltIf,'display_on_map',Genivi.data['display_on_map']);
                entryMenu(dltIf,"NavigationAppBrowseMap",menu);
            }
		}
        StdButton {
            source:StyleSheet.settings[Constants.SOURCE]; x:StyleSheet.settings[Constants.X]; y:StyleSheet.settings[Constants.Y]; width:StyleSheet.settings[Constants.WIDTH]; height:StyleSheet.settings[Constants.HEIGHT];
            id:settings;  next:back; prev:select_display_on_map;
            disabled: false;
            onClicked: {
                disconnectSignals();
                entryMenu(dltIf,"NavigationAppSettings",menu);
            }
        }
        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back;
			text: Genivi.gettext("Back"); 
            onClicked: {
                disconnectSignals();
                rootMenu(dltIf,"NavigationAppBrowseMap");
            }
		}	
	}
	Component.onCompleted: {
        connectSignals();

        var categoriesIdNameAndRadius=[];
        var ret=Genivi.poisearch_GetAvailableCategories(dbusIf,dltIf);
        Genivi.categoriesIdNameList=ret[1];

        for (var j = 0 ; j < Genivi.categoriesIdNameList.length ; j+=2) {
            if (Genivi.categoriesIdNameList[j+1][3] === Genivi.default_category_name) {
                Genivi.category_id=Genivi.categoriesIdNameList[j+1][1];
                poiCategoryName=Genivi.categoriesIdNameList[j+1][3];
            }
         }

        categoryValue.text=poiCategoryName;
        keyboardArea.destination=poiValue; // by default
        keyboardArea.setactivekeys(Genivi.allKeys,true);
        poiFrame.visible=true;

        //launch a search on the default category
        clearSearch();
        searchPois();

        if(!Genivi.showroom) {
            updateCurrentPosition();
        }
    }
}
