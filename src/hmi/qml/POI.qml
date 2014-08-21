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
import "Core/style-sheets/fsa-poi-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    text: Genivi.gettext("POI")
    headlineFg: "grey"
    headlineBg: "blue"
    DBusIf {
    	id: dbusIf
    }

    function update()
    {
        selectedStationValue.text="See details of \nthe station \nhere"
    }
    HMIBgImage {
        image:StyleSheet.fsa_poi_menu_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight }
		Text {
            x:StyleSheet.searchResultTitle[Constants.X]; y:StyleSheet.searchResultTitle[Constants.Y]; width:StyleSheet.searchResultTitle[Constants.WIDTH]; height:StyleSheet.searchResultTitle[Constants.HEIGHT];color:StyleSheet.searchResultTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.searchResultTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.searchResultTitle[Constants.PIXELSIZE];
            id:searchResultTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("SearchResult")
	   	}
		Text {
            x:StyleSheet.selectedStationTitle[Constants.X]; y:StyleSheet.selectedStationTitle[Constants.Y]; width:StyleSheet.selectedStationTitle[Constants.WIDTH]; height:StyleSheet.selectedStationTitle[Constants.HEIGHT];color:StyleSheet.selectedStationTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.selectedStationTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.selectedStationTitle[Constants.PIXELSIZE];
            id:selectedStationTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("SelectedStation")
	   	}
		Text {
            x:StyleSheet.selectedStationValue[Constants.X]; y:StyleSheet.selectedStationValue[Constants.Y]; width:StyleSheet.selectedStationValue[Constants.WIDTH]; height:StyleSheet.selectedStationValue[Constants.HEIGHT];color:StyleSheet.selectedStationValue[Constants.TEXTCOLOR];styleColor:StyleSheet.selectedStationValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.selectedStationValue[Constants.PIXELSIZE];
            id:selectedStationValue
            style: Text.Sunken;
            smooth: true
            clip: true
			text: " "
        }
		Component {
            id: searchResultList
            Text {
                x:StyleSheet.searchResultValue[Constants.X]; y:StyleSheet.searchResultValue[Constants.Y]; width:StyleSheet.searchResultValue[Constants.WIDTH]; height:StyleSheet.searchResultValue[Constants.HEIGHT];color:StyleSheet.searchResultValue[Constants.TEXTCOLOR];styleColor:StyleSheet.searchResultValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.searchResultValue[Constants.PIXELSIZE];
                id:searchResultValue;
				property real index:number;
				text: name;
				style: Text.Sunken;
				smooth: true
			}
		}
		HMIList {
            x:StyleSheet.searchResultList[Constants.X]; y:StyleSheet.searchResultList[Constants.Y]; width:StyleSheet.searchResultList[Constants.WIDTH]; height:StyleSheet.searchResultList[Constants.HEIGHT];
			property real selectedEntry
			id:view
            delegate: searchResultList
            next:select_search_for_refill
			prev:back
			onSelected:{
				if (what) {
					Genivi.poi_id=what.index;
					var poi_data=Genivi.poi_data[what.index];
        				selectedStationValue.text="Name:"+poi_data.name+"\nID:"+poi_data.id+"\nLat:"+poi_data.lat+"\nLon:"+poi_data.lon;
					select_reroute.disabled=false;
            				select_display_on_map.disabled=false;
				} else {
					Genivi.poi_id=null;
        				selectedStationValue.text="";
					select_reroute.disabled=true;
					select_display_on_map.disabled=true;
				}
			}
		}
		StdButton { 
            source:StyleSheet.select_search_for_refill[Constants.SOURCE]; x:StyleSheet.select_search_for_refill[Constants.X]; y:StyleSheet.select_search_for_refill[Constants.Y]; width:StyleSheet.select_search_for_refill[Constants.WIDTH]; height:StyleSheet.select_search_for_refill[Constants.HEIGHT];
            id:select_search_for_refill
			explode: false
			onClicked: {
				var model=view.model;
				var ids=[];
				var position=Genivi.nav_message(dbusIf,"MapMatchedPosition","GetPosition",["array",["uint16",Genivi.NAVIGATIONCORE_LATITUDE,"uint16",Genivi.NAVIGATIONCORE_LONGITUDE]]);
				var category;
				if (!position[1][3][1] && !position[1][7][1]) {
					model.clear();
					model.append({"name":"No position available"});
					return;
				}
				// Genivi.dump("",Genivi.poisearch_message_get(dbusIf,"GetVersion",[]));
				// Genivi.dump("",Genivi.poisearch_message_get(dbusIf,"GetLanguage",[]));
				var categories=Genivi.poisearch_message_get(dbusIf,"GetAvailableCategories",[]);
				for (var i = 0 ; i < categories.length ; i+=2) { 
					if (categories[i+1][1][3] == 'fuel') {
						// Genivi.dump("",categories[i+1][1]);
						category=categories[i+1][1][1];
					}
				}
				// Genivi.dump("",Genivi.poisearch_message_get(dbusIf,"GetRootCategory",[]));
				Genivi.poisearch_message(dbusIf,"SetCenter",["structure",["double",position[1][3][1],"double",position[1][7][1],"int32",0]]);
				Genivi.poisearch_message(dbusIf,"SetCategories",["array",["structure",["uint16",category,"uint32",1000]]]);
				Genivi.poisearch_message(dbusIf,"StartPoiSearch",["string","","uint16",Genivi.POISERVICE_SORT_BY_DISTANCE]);
				var res=Genivi.poisearch_message(dbusIf,"RequestResultList",["uint16",0,"uint16",10000,"array",["string","name"]]);
				var res_win=res[5];
				for (var i = 0 ; i < res_win.length ; i+=2) {
					ids.push(res_win[i+1][0]);
					ids.push(res_win[i+1][1]);
					var id=res_win[i+1][1];
					Genivi.poi_data[id]=[];
					Genivi.poi_data[id].id=id;
					Genivi.poi_data[id].distance=res_win[i+1][3];
				}
				var details=Genivi.poisearch_message_get(dbusIf,"GetPoiDetails",["array",ids]);
				for (var i = 0 ; i < details[1].length ; i+=2) {
					var poi_details=details[1][i+1];
					var id=poi_details[1][1];
					Genivi.poi_data[id].name=poi_details[1][3];
					Genivi.poi_data[id].lat=poi_details[1][5];
					Genivi.poi_data[id].lon=poi_details[1][7];
				}
				// Genivi.dump("",details);
				model.clear();
				for (var i = 0 ; i < ids.length ; i+=2) {
					var id=ids[i+1];
					var poi_data=Genivi.poi_data[id];
					model.append({"name":Genivi.distance(poi_data.distance)+" "+poi_data.name,"number":id});
				}
			}
		}
		Text {
            x:StyleSheet.searchTitle[Constants.X]; y:StyleSheet.searchTitle[Constants.Y]; width:StyleSheet.searchTitle[Constants.WIDTH]; height:StyleSheet.searchTitle[Constants.HEIGHT];color:StyleSheet.searchTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.searchTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.searchTitle[Constants.PIXELSIZE];
            id:searchTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("SearchForPOI")
        }
		StdButton { 
            source:StyleSheet.select_reroute[Constants.SOURCE]; x:StyleSheet.select_reroute[Constants.X]; y:StyleSheet.select_reroute[Constants.Y]; width:StyleSheet.select_reroute[Constants.WIDTH]; height:StyleSheet.select_reroute[Constants.HEIGHT];
            id:select_reroute;
            explode:false;
	    disabled:true;
            next:select_display_on_map; prev:select_search_for_refill
			onClicked: {
				var poi_data=Genivi.poi_data[Genivi.poi_id];
				var dest=["uint16",Genivi.NAVIGATIONCORE_LATITUDE,"variant",["double",poi_data.lat],"uint16",Genivi.NAVIGATIONCORE_LONGITUDE,"variant",["double",poi_data.lon]];
				Genivi.routing_message(dbusIf,"SetWaypoints",["boolean",true,"array",["map",dest]]);
				Genivi.data['calculate_route']=true;
				Genivi.data['lat']='';
				Genivi.data['lon']='';
				pageOpen("NavigationCalculatedRoute");
			}
		}
		Text {
            x:StyleSheet.rerouteTitle[Constants.X]; y:StyleSheet.rerouteTitle[Constants.Y]; width:StyleSheet.rerouteTitle[Constants.WIDTH]; height:StyleSheet.rerouteTitle[Constants.HEIGHT];color:StyleSheet.rerouteTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.rerouteTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.rerouteTitle[Constants.PIXELSIZE];
            id:rerouteTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Reroute")
        }
        StdButton {
            source:StyleSheet.select_display_on_map[Constants.SOURCE]; x:StyleSheet.select_display_on_map[Constants.X]; y:StyleSheet.select_display_on_map[Constants.Y]; width:StyleSheet.select_display_on_map[Constants.WIDTH]; height:StyleSheet.select_display_on_map[Constants.HEIGHT];
            id:select_display_on_map;
            explode:false;
	    disabled:true;
            next:back; prev:select_reroute
			onClicked: {
				var poi_data=Genivi.poi_data[Genivi.poi_id];
				Genivi.data['show_position']=new Array;
				Genivi.data['show_position']['lat']=poi_data.lat;
				Genivi.data['show_position']['lon']=poi_data.lon;
				Genivi.data['mapback']="POI";
				pageOpen("NavigationBrowseMap");
			}
		}
		Text {
            x:StyleSheet.displayTitle[Constants.X]; y:StyleSheet.displayTitle[Constants.Y]; width:StyleSheet.displayTitle[Constants.WIDTH]; height:StyleSheet.displayTitle[Constants.HEIGHT];color:StyleSheet.displayTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.displayTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.displayTitle[Constants.PIXELSIZE];
            id:displayTitle;
            style: Text.Sunken;
            smooth: true;
            text: Genivi.gettext("DisplayPOI")
        }
        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back;
			text: Genivi.gettext("Back"); 
			disabled:false; 
            next:select_search_for_refill; prev:select_display_on_map;
			page:"MainMenu"
		}	
	}
	Component.onCompleted: {
		Genivi.poi_data=[];
		update();
	}
}
