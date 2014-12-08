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
import QtQuick 2.1 
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/navigation-search-freetext-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
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
		Genivi.dump("",args);
		if (args[3] == 2) 
            console.log("Searching");
		else
            console.log("FreeText");
	}

	function searchResultList(args)
	{
		Genivi.dump("",args);
		Genivi.locationinput_message(dbusIf,"SelectEntry",["uint16",0]);
	}

	function contentUpdated(args)
	{
		country="";
		city="";
		street="";
		number="";
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
        image:StyleSheet.navigation_search_by_freetext_menu_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

        Text {
            x:StyleSheet.textTitle[Constants.X]; y:StyleSheet.textTitle[Constants.Y]; width:StyleSheet.textTitle[Constants.WIDTH]; height:StyleSheet.textTitle[Constants.HEIGHT];color:StyleSheet.textTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.textTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.textTitle[Constants.PIXELSIZE];
            id:textTitle;
            style: Text.Sunken;
            smooth: true;
            text: Genivi.gettext("Text");
        }
		EntryField {
            x:StyleSheet.textValue[Constants.X]; y:StyleSheet.textValue[Constants.Y]; width: StyleSheet.textValue[Constants.WIDTH]; height: StyleSheet.textValue[Constants.HEIGHT];
            id: textValue
			criterion: Genivi.NAVIGATIONCORE_FULL_ADDRESS
			globaldata: 'location_input'
			textfocus: true
            next: ok
			prev: back
			onLeave:{menu.leave(0)}
		}
        StdButton {
            source:StyleSheet.ok[Constants.SOURCE]; x:StyleSheet.ok[Constants.X]; y:StyleSheet.ok[Constants.Y]; width:StyleSheet.ok[Constants.WIDTH]; height:StyleSheet.ok[Constants.HEIGHT];textColor:StyleSheet.okText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.okText[Constants.PIXELSIZE];
            id:ok
            text:Genivi.gettext("Ok")
            next:back
            prev:textValue
            explode:false
            onClicked:{
                accept(textValue);
/*
                leave(1);
                Genivi.data['lat']=menu.lat;
                Genivi.data['lon']=menu.lon;
                Genivi.data['description']=country.text;
                pageOpen("NavigationRoute");
*/
        }
        }
        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); explode:false; next:textValue; prev:ok;
            onClicked:{leave(1); pageOpen("NavigationSearch");}
        }
    }
}
