/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationSearchFreeText.qml
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
import QtQuick 1.0
import "Core"
import "Core/genivi.js" as Genivi;

HMIMenu {
	id: menu
    headlineFg: "grey"
    headlineBg: "blue"
    text: Genivi.gettext("NavigationSearchFreeText")
	property string pagefile:"NavigationSearchFreeText"
	property Item searchStatusSignal;
	property Item searchResultListSignal;
	property Item contentUpdatedSignal;
	property real lat
	property real lon
	property string country;
	property string city;
	property string street;
	property string number;

	function searchStatus(args)
	{
		console.log("SearchStatus");
		Genivi.dump("",args);
		if (args[3] == 2) 
			menu.text="FreeText (Searching)";
		else
			menu.text="FreeText";
	}

	function searchResultList(args)
	{
		console.log("SearchResultList:");
		Genivi.dump("",args);
		Genivi.locationinput_message(dbusIf,"SelectEntry",["uint16",0]);
	}

	function contentUpdated(args)
	{
		country="";
		city="";
		street="";
		number="";
		console.log("contentUpdated:");
		args=args[7];
		Genivi.dump("",args);
		for (var i=0 ; i < args.length ; i+=4) {
			if (args[i+1] == Genivi.NAVIGATIONCORE_LATITUDE) lat=args[i+3][1];
			if (args[i+1] == Genivi.NAVIGATIONCORE_LONGITUDE) lon=args[i+3][1];
			if (args[i+1] == Genivi.NAVIGATIONCORE_COUNTRY) country=args[i+3][1];
			if (args[i+1] == Genivi.NAVIGATIONCORE_CITY) city=args[i+3][1];
			if (args[i+1] == Genivi.NAVIGATIONCORE_STREET) street=args[i+3][1];
			if (args[i+1] == Genivi.NAVIGATIONCORE_HOUSENUMBER) number=args[i+3][1];
		}
		leave(1);
		Genivi.data['lat']=lat;
		Genivi.data['lon']=lon;
		Genivi.data['description']=country+" "+city+" "+street+" "+number;
		pageOpen("NavigationRoute");
	}

	function connectSignals()
	{
		searchStatusSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","SearchStatus",menu,"searchStatus");
		searchResultListSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","SearchResultList",menu,"searchResultList");
		contentUpdatedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","ContentUpdated",menu,"contentUpdated");
	}
	
	function disconnectSignals()
	{
		searchStatusSignal.destroy();
		searchResultListSignal.destroy();
		contentUpdatedSignal.destroy();
	}

	function accept(what)
	{
		console.log(what);
		console.log("accept "+what.criterion+" "+what.text);
		Genivi.locationinput_message(dbusIf,"SetSelectionCriterion",["uint16",what.criterion]);
		Genivi.locationinput_message(dbusIf,"Search",["string",what.text,"uint16",10]);
	}


	function leave(toOtherMenu)
	{
		disconnectSignals();
		if (toOtherMenu) {
			Genivi.loc_handle_clear(dbusIf);
		}
		//Genivi.nav_session_clear(dbusIf);
	}

	DBusIf {
                id: dbusIf
		Component.onCompleted: {
			connectSignals();		
			
			var res=Genivi.nav_message(dbusIf,"Session","GetVersion",[]);
			Genivi.dump("",res);
			if (res[0] != "error") {
				console.log("NavigationCore Version "+res[1][1]+"."+res[1][3]+"."+res[1][5]+" "+res[1][7]);
				res=Genivi.nav_session(dbusIf);
				res=Genivi.loc_handle(dbusIf);
			} else {
				Genivi.dump("",res);
			}
			if (Genivi.entryselectedentry) {
				Genivi.locationinput_message(dbusIf,"SelectEntry",["uint16",Genivi.entryselectedentry-1]);
			}
		}
        }

    HMIBgImage {
        image:"navigation-search-by-freetext-menu-background";
        anchors { fill: parent; topMargin: parent.headlineHeight}
        //Important notice: x,y coordinates from the left/top origin of the component
        //so take in account the header height and substract it

        Text {
                height:menu.hspc
                x:100; y:30;
                font.pixelSize: 25;
                style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true;
                text: Genivi.gettext("Text");
        }
		EntryField {
            x:100; y:74; width:280; height:60;
            id: text
			criterion: Genivi.NAVIGATIONCORE_FULL_ADDRESS
			globaldata: 'location_input'
			textfocus: true
			next: ok
			prev: back
			onLeave:{menu.leave(0)}
		}
        StdButton {
            textColor:"black";
            pixelSize:38 ;
            source:"Core/images/ok.png";
            x:20; y:374; width:180; height:60;
            text:Genivi.gettext("Ok")
            id:ok
            next:back
            prev:text
            explode:false
            onClicked:{
                accept(text);
/*
                leave(1);
                Genivi.data['lat']=menu.lat;
                Genivi.data['lon']=menu.lon;
                Genivi.data['description']=country.text;
                pageOpen("NavigationRoute");
*/
        }
        }
        StdButton { textColor:"black"; pixelSize:38 ;source:"Core/images/back.png"; x:600; y:374; width:180; height:60;id:back; text: Genivi.gettext("Back"); explode:false; next:text; prev:ok;
            onClicked:{leave(1); pageOpen("NavigationSearch");}
        }
    }
}
