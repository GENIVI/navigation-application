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
import QtQuick 1.0
import "Core"
import "Core/genivi.js" as Genivi;

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
        station_details.text="See details of \nthe station here"
    }
    HMIBgImage {
		image:"fsa-poi-menu-background";
//Important notice: x,y coordinates from the left/top origin, so take in account the header of 26 pixels high
		anchors { fill: parent; topMargin: parent.headlineHeight }
		Text {
            height:menu.hspc
			x:122; y:20;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("SearchResult")
	   	}
		Text {
            height:menu.hspc
			x:470; y:20;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("SelectedStation")
	   	}
		Text {
			id:station_details
            height:menu.hspc
			x:484; y:76;
            font.pixelSize: 20;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
			text: " "
        }
		Component {
			id: listDelegate
			Text {
				width: 180;
				height: 20;
				id:text;
				text: name;
				font.pixelSize: 20;
				style: Text.Sunken;
				color: "white";
				styleColor: "black";
				smooth: true
			}
		}
		HMIList {
			x:45; y:51; width:330; height:290;
			property real selectedEntry
			id:view
			delegate: listDelegate
			next:search
			prev:back
		}
		StdButton { 
			source:"Core/images/select-search-for-refill.png";
			x:408; y:246; width:100; height:60;
			id:search
			explode: false
			onClicked: {
				var model=view.model;
				var ids=[];
				var distance=[];
				var name=[];
				console.log("test");
				Genivi.dump("",Genivi.poisearch_message_get(dbusIf,"GetVersion",[]));
				Genivi.dump("",Genivi.poisearch_message_get(dbusIf,"GetLanguage",[]));
				Genivi.dump("",Genivi.poisearch_message_get(dbusIf,"GetAvailableCategories",[]));
				Genivi.dump("",Genivi.poisearch_message_get(dbusIf,"GetRootCategory",[]));
				Genivi.poisearch_message(dbusIf,"SetCenter",["structure",["double",46.2,"double",6.15,"int32",0]]);
				Genivi.poisearch_message(dbusIf,"SetCategories",["array",["structure",["uint16",256,"uint32",1000]]]);
				Genivi.poisearch_message(dbusIf,"StartPoiSearch",["string","","uint16",560]);
				var res=Genivi.poisearch_message(dbusIf,"RequestResultList",["uint16",0,"uint16",10000,"array",["string","name"]]);
				var res_win=res[5];
				for (var i = 0 ; i < res_win.length ; i+=2) {
					ids.push(res_win[i+1][0]);
					ids.push(res_win[i+1][1]);
					distance[res_win[i+1][1]]=res_win[i+1][3];
				}
				var details=Genivi.poisearch_message_get(dbusIf,"GetPoiDetails",["array",ids]);
				for (var i = 0 ; i < details[1].length ; i+=2) {
					var poi_details=details[1][i+1];
					name[poi_details[1][1]]=poi_details[1][3];
				}	
				// Genivi.dump("",details);
				for (var i = 0 ; i < ids.length ; i+=2) {
					var id=ids[i+1];
					model.append({"name":distance[id]+" "+name[id]});
				}
			}
		}
		Text {
            height:menu.hspc
			x:408; y:316;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("SearchForPOI")
        }
		StdButton { 
			source:"Core/images/select-reroute.png";
			x:534; y:246; width:100; height:60;
			id:reroute; 
            explode:false;
			next:display; prev:search
		}
		Text {
            height:menu.hspc
			x:534; y:316;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("Reroute")
        }
		StdButton { 
			source:"Core/images/select-display-on-map.png";
			x:658; y:246; width:100; height:60;
            id:display;
            explode:false;
			next:back; prev:reroute
		}
		Text {
            height:menu.hspc
			x:658; y:316;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("DisplayPOI")
        }
		StdButton { 
			textColor:"black"; pixelSize:38 ; 
			source:"Core/images/back.png"; 
			x:600; y:374; width:180; height:60; 
			id:back; 
			text: Genivi.gettext("Back"); 
			disabled:false; 
			next:search; prev:display; 
			page:"MainMenu"
		}	
	}
	Component.onCompleted: {
		update();
	}
}
