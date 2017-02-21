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
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/NavigationAppPOI-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

NavigationAppHMIMenu {
	id: menu
    property string pagefile:"NavigationAppPOI"
    property string extraspell;
    property int type_poi_car_parking: 65842
    property int type_poi_hotel: 65835
    property int type_poi_restaurant: 65923
    property int type_poi_bar: 65848
    property int type_poi_fuel: 65834
    property string poiCategoryName
    property bool vehicleLocated: false

    //------------------------------------------//
    // Management of the DBus exchanges
    //------------------------------------------//
    DBusIf {
    	id: dbusIf
    }

    property Item mapmatchedpositionPositionUpdateSignal;
    function mapmatchedpositionPositionUpdate(args)
    {
        Genivi.hookSignal("mapmatchedpositionPositionUpdate");
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
        var res=Genivi.mapmatchedposition_GetPosition(dbusIf);
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
        select_search.update();
    }

    function update()
    {
        selectedValue.text="See details of \nthe POI \nhere"
    }

    function spell(input)
    {
        keyboardArea.destination.text = input;
    }

    function displayPOIList()
    {
        var model=view.model;
        for(var i=0;i<Genivi.categoriesIdNameList.length;i+=2)
        {
            model.append({"name":Genivi.categoriesIdNameList[i+1][3],"number":i/2});
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

    NavigationAppHMIBgImage {
        image:StyleSheet.navigation_app_poi_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight }

        StdButton {
            source:StyleSheet.categoryKeyboard[Constants.SOURCE]; x:StyleSheet.categoryKeyboard[Constants.X]; y:StyleSheet.categoryKeyboard[Constants.Y]; width:StyleSheet.categoryKeyboard[Constants.WIDTH]; height:StyleSheet.categoryKeyboard[Constants.HEIGHT];
            id:categoryKeyboard; disabled:false; next:poiKeyboard; prev:back;
            onClicked: {
                keyboardArea.destination=categoryValue;
                poiValue.text="";
                categoryValue.text=poiCategoryName;
                poiFrame.visible=false;
                categoryFrame.visible=true;
                view.model.clear();
                displayPOIList();
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
            next: select_search
            prev: back
            onLeave:{}
        }
        StdButton {
            source:StyleSheet.poiKeyboard[Constants.SOURCE]; x:StyleSheet.poiKeyboard[Constants.X]; y:StyleSheet.poiKeyboard[Constants.Y]; width:StyleSheet.poiKeyboard[Constants.WIDTH]; height:StyleSheet.poiKeyboard[Constants.HEIGHT];
            id:poiKeyboard; disabled:false; next:select_search; prev:back;
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
            next: select_search
            prev: back
            onLeave:{}
        }

        Text {
            x:StyleSheet.selectedValueTitle[Constants.X]; y:StyleSheet.selectedValueTitle[Constants.Y]; width:StyleSheet.selectedValueTitle[Constants.WIDTH]; height:StyleSheet.selectedValueTitle[Constants.HEIGHT];color:StyleSheet.selectedValueTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.selectedValueTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.selectedValueTitle[Constants.PIXELSIZE];
            id:selectedValueTitle;
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
			text: " "
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
            next:select_search
			prev:back
			onSelected:{
                if(keyboardArea.destination===poiValue)
                {
                    if (what) {
                        Genivi.poi_id=what.index;
                        var poi_data=Genivi.poi_data[what.index];
                        selectedValue.text="Name:"+poi_data.name+"\nID:"+poi_data.id+"\nLat:"+poi_data.lat+"\nLon:"+poi_data.lon;
                        select_reroute.disabled=false;
                        select_display_on_map.disabled=false;
                        keyboardArea.destination.text=poi_data.name;
                    } else {
                        Genivi.poi_id=null;
                        selectedValue.text="";
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
                   } else {
                       keyboardArea.destination.text=""
                   }
                }

			}
		}       

        NavigationAppKeyboard {
            x:StyleSheet.keyboardArea[Constants.X]; y:StyleSheet.keyboardArea[Constants.Y]; width:StyleSheet.keyboardArea[Constants.WIDTH]; height:StyleSheet.keyboardArea[Constants.HEIGHT];
            id: keyboardArea;
            destination: poiValue;
            firstLayout: "ABC";
            secondLayout: "abc";
            next: select_search;
            prev: poiKeyboard;
            onKeypress: {   }
        }

        StdButton {
            source:StyleSheet.select_search[Constants.SOURCE]; x:StyleSheet.select_search[Constants.X]; y:StyleSheet.select_search[Constants.Y]; width:StyleSheet.select_search[Constants.WIDTH]; height:StyleSheet.select_search[Constants.HEIGHT];
            id:select_search
            disabled:!(vehicleLocated || Genivi.showroom );
            onClicked: {
				var model=view.model;
				var ids=[];
                var latitude=0;
                var longitude=0;

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

                Genivi.poisearch_SetCenter(dbusIf,latitude,longitude,0);
                Genivi.poisearch_SetCategories(dbusIf,categoriesAndRadiusList);
                Genivi.poisearch_StartPoiSearch(dbusIf,"",Genivi.POISERVICE_SORT_BY_DISTANCE);
                var attributeList=[];
                attributeList[0]=0;
                var res=Genivi.poisearch_RequestResultList(dbusIf,Genivi.offset,Genivi.maxWindowSize,attributeList);
				var res_win=res[5];
                var i;
                for (i = 0 ; i < res_win.length ; i+=2) {
                    var id=res_win[i+1][1];
                    ids.push(id);
					Genivi.poi_data[id]=[];
					Genivi.poi_data[id].id=id;
					Genivi.poi_data[id].distance=res_win[i+1][3];
				}
                var details=Genivi.poisearch_GetPoiDetails(dbusIf,ids);
                for (i = 0 ; i < details[1].length ; i+=2) {
					var poi_details=details[1][i+1];
                    id=poi_details[1][1];
					Genivi.poi_data[id].name=poi_details[1][3];
                    Genivi.poi_data[id].lat=poi_details[1][5][1];
                    Genivi.poi_data[id].lon=poi_details[1][5][3];
				}
				model.clear();
                for (i = 0 ; i < ids.length ; i+=1) {
                    id=ids[i];
					var poi_data=Genivi.poi_data[id];
					model.append({"name":Genivi.distance(poi_data.distance)+" "+poi_data.name,"number":id});
				}
			}
		}
		StdButton { 
            source:StyleSheet.select_reroute[Constants.SOURCE]; x:StyleSheet.select_reroute[Constants.X]; y:StyleSheet.select_reroute[Constants.Y]; width:StyleSheet.select_reroute[Constants.WIDTH]; height:StyleSheet.select_reroute[Constants.HEIGHT];
            id:select_reroute;            
            disabled:true;
            next:select_display_on_map; prev:select_search
			onClicked: {
                disconnectSignals();
                Genivi.data['destination']=Genivi.poi_data[Genivi.poi_id];
                Genivi.reroute_requested=true;
                pageOpen("NavigationAppSearch");
			}
		}
        StdButton {
            source:StyleSheet.select_display_on_map[Constants.SOURCE]; x:StyleSheet.select_display_on_map[Constants.X]; y:StyleSheet.select_display_on_map[Constants.Y]; width:StyleSheet.select_display_on_map[Constants.WIDTH]; height:StyleSheet.select_display_on_map[Constants.HEIGHT];
            id:select_display_on_map;           
            disabled:true;
            next:back; prev:select_reroute
			onClicked: {
                disconnectSignals();
                var poi_data=Genivi.poi_data[Genivi.poi_id];
                Genivi.data['position']['lat']=poi_data.lat;
                Genivi.data['position']['lon']=poi_data.lon;
                entryMenu("NavigationAppBrowseMap",menu);
            }
		}
        StdButton {
            source:StyleSheet.settings[Constants.SOURCE]; x:StyleSheet.settings[Constants.X]; y:StyleSheet.settings[Constants.Y]; width:StyleSheet.settings[Constants.WIDTH]; height:StyleSheet.settings[Constants.HEIGHT];
            id:settings;  next:back; prev:select_display_on_map;
            disabled: false;
            onClicked: {
                disconnectSignals();
                entryMenu("NavigationAppSettings",menu);
            }
        }
        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back;
			text: Genivi.gettext("Back"); 
			disabled:false; 
            next:select_search; prev:select_display_on_map;
            onClicked: {
                disconnectSignals();
                Genivi.preloadMode=true;
                leaveMenu();
            }
		}	
	}
	Component.onCompleted: {
        connectSignals();

        var categoriesIdNameAndRadius=[];
        var ret=Genivi.poisearch_GetAvailableCategories(dbusIf);
        var categories=ret[1];
        for (var i = 0 ; i < categories.length ; i+=2) {
            if (categories[i+1][3] == 'fuel') {
                Genivi.category_id=categories[i+1][1];
                poiCategoryName=categories[i+1][3];
            }
         }
        Genivi.categoriesIdNameList=categories;

        Genivi.poi_data=[];

        categoryValue.text=poiCategoryName;
        keyboardArea.destination=poiValue; // by default
        poiFrame.visible=true;

		update();
        if(!Genivi.showroom) {
            updateCurrentPosition();
        }
    }
}
