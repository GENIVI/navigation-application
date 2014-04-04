/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationSearchAddress.qml
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
    text: Genivi.gettext("NavigationSearchAddress")
	property string pagefile:"NavigationSearchAddress"
	property Item currentSelectionCriterionSignal;
	property Item searchStatusSignal;
	property Item searchResultListSignal;
	property Item contentUpdatedSignal;
	property real lat
	property real lon

    function loadWithAddress()
    {
        //load the field with saved values
        if (Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY] !== "")
        {//need to test empty string
            country.text=Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY];
            accept(country);
            city.disabled=false;
            if (Genivi.address[Genivi.NAVIGATIONCORE_CITY] !== "")
            {
                city.text=Genivi.address[Genivi.NAVIGATIONCORE_CITY];
                street.disabled=false;
                accept(city);
            }
        }
    }

	function currentSelectionCriterion(args)
	{
		console.log("CurrentSelectionCriterion");
		Genivi.dump("",args);
	}

	function searchStatus(args)
	{
		console.log("SearchStatus");
		Genivi.dump("",args);
		if (args[3] == 2) 
			menu.text="Search (Searching)";
		else
			menu.text="Search";
	}

	function searchResultList(args)
	{
		console.log("SearchResultList:");
		Genivi.dump("",args);
		Genivi.locationinput_message(dbusIf,"SelectEntry",["uint16",0]);
	}

	function setContent(args)
	{
		country.text="";
		city.text="";
		street.text="";
		number.text="";
		for (var i=0 ; i < args.length ; i+=4) {
			if (args[i+1] == Genivi.NAVIGATIONCORE_LATITUDE) lat=args[i+3][1];
			if (args[i+1] == Genivi.NAVIGATIONCORE_LONGITUDE) lon=args[i+3][1];
			if (args[i+1] == Genivi.NAVIGATIONCORE_COUNTRY) country.text=args[i+3][1];
			if (args[i+1] == Genivi.NAVIGATIONCORE_CITY) city.text=args[i+3][1];
			if (args[i+1] == Genivi.NAVIGATIONCORE_STREET) street.text=args[i+3][1];
			if (args[i+1] == Genivi.NAVIGATIONCORE_HOUSENUMBER) number.text=args[i+3][1];
		}
	}

	function setDisabled(args)
	{
		country.disabled=true;
		city.disabled=true;
		street.disabled=true;
		number.disabled=true;
		for (var i=0 ; i < args.length ; i++) {
			if (args[i] == Genivi.NAVIGATIONCORE_COUNTRY) country.disabled=false;
			if (args[i] == Genivi.NAVIGATIONCORE_CITY) city.disabled=false;
			if (args[i] == Genivi.NAVIGATIONCORE_STREET) street.disabled=false;
			if (args[i] == Genivi.NAVIGATIONCORE_HOUSENUMBER) number.disabled=false;
		}
		if (country.disabled)
			country.text="";
		if (city.disabled)
			city.text="";
		if (street.disabled)
			street.text="";
		if (number.disabled)
			number.text="";
	}

	function setFocus()
	{
		var focus;
		if (!country.disabled)
			focus=country;
		if (!city.disabled)
			focus=city;
		if (!street.disabled)
			focus=street;
		if (!number.disabled)
			focus=number;
		focus.takeFocus();
	}

	function contentUpdated(args)
	{
		console.log("contentUpdated");
		Genivi.dump("",args);
		if (args[3]) {
			ok.disabled=false;
		}
		setDisabled(args[5]);
		setContent(args[7]);
		setFocus();
	}

	function connectSignals()
	{
		currentSelectionCriterionSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","CurrentSelectionCriterion",menu,"currentSelectionCriterion");
		searchStatusSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","SearchStatus",menu,"searchStatus");
		searchResultListSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","SearchResultList",menu,"searchResultList");
		contentUpdatedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","ContentUpdated",menu,"contentUpdated");
	}
	
	function disconnectSignals()
	{
		currentSelectionCriterionSignal.destroy();
		searchStatusSignal.destroy();
		searchResultListSignal.destroy();
		contentUpdatedSignal.destroy();
	}

	function accept(what)
	{
		console.log(what);
		console.log("accept "+what.criterion+" "+what.text);
		ok.disabled=true;
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
			if (Genivi.entrydest == 'country') accept(country);
			if (Genivi.entrydest == 'city') accept(city);
			if (Genivi.entrydest == 'street') accept(street);
			if (Genivi.entrydest == 'number') accept(number);
			Genivi.entrydest=null;
		}
        }

    HMIBgImage {
        image:"navigation-search-by-address-menu-background";
        anchors { fill: parent; topMargin: parent.headlineHeight}
        //Important notice: x,y coordinates from the left/top origin of the component
        //so take in account the header height and substract it
        id: content

        Text {
                height:menu.hspc
                x:100; y:30;
                font.pixelSize: 25;
                style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true;
                text: Genivi.gettext("Country");
        }
        EntryField {
			id: country
            x:100; y:74; width:280; height:60;
			criterion: Genivi.NAVIGATIONCORE_COUNTRY
			globaldata: 'country'
			textfocus: true
			next: city
			prev: back
			onLeave:{menu.leave(0)}
		}
        Text {
                height:menu.hspc
                x:460; y:30;
                font.pixelSize: 25;
                style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true;
                text: Genivi.gettext("Street");
        }
		EntryField {
			id:street
            x:460; y:74; width:280; height:60;
			criterion: Genivi.NAVIGATIONCORE_STREET
			globaldata: 'street'
			next: number
			prev: city
			disabled: true
			onLeave:{menu.leave(0)}
		}
        Text {
                height:menu.hspc
                x:100; y:180;
                font.pixelSize: 25;
                style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true;
                text: Genivi.gettext("City");
        }
        EntryField {
			id:city
            x:100; y:224; width:280; height:60;
			criterion: Genivi.NAVIGATIONCORE_CITY
			globaldata: 'city'
			next:street
			prev:country
			disabled: true
			onLeave:{menu.leave(0)}
		}
        Text {
                height:menu.hspc
                x:460; y:180;
                font.pixelSize: 25;
                style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true;
                text: Genivi.gettext("Number");
        }
        EntryField {
			id:number
            x:460; y:224; width:280; height:60;
			criterion: Genivi.NAVIGATIONCORE_HOUSENUMBER
			globaldata: 'number'
			next: ok
			prev: street
			disabled: true
			onLeave:{menu.leave(0)}
		}

        StdButton {
            textColor:"black";
            pixelSize:38 ;
            source:"Core/images/ok.png";
            x:20; y:374; width:180; height:60;
            id:ok
            next:back
            prev:number
            text:Genivi.gettext("Ok")
            disabled: true
            onClicked:{
                leave(1);
                //save address for next time
                Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY]=country.text;
                Genivi.address[Genivi.NAVIGATIONCORE_CITY]=city.text;
                Genivi.address[Genivi.NAVIGATIONCORE_STREET]=street.text;
                Genivi.address[Genivi.NAVIGATIONCORE_HOUSENUMBER]=number.text;
                Genivi.data['lat']=menu.lat;
                Genivi.data['lon']=menu.lon;
                Genivi.data['description']=country.text;
                if (!city.disabled)
                    Genivi.data['description']+=' '+city.text;
                if (!street.disabled)
                    Genivi.data['description']+=' '+street.text;
                if (!number.disabled)
                    Genivi.data['description']+=' '+number.text;
                //save entered location into the history
                Genivi.updateHistoryOfLastEnteredLocation(Genivi.data['description'],Genivi.data['lat'],Genivi.data['lon']);
                pageOpen("NavigationRoute");
            }
        }

        StdButton { textColor:"black"; pixelSize:38 ;source:"Core/images/back.png"; x:600; y:374; width:180; height:60;id:back; text: Genivi.gettext("Back"); explode:false; next:country; prev:ok;
            onClicked:{leave(1); pageOpen("NavigationSearch");}
        }
	}
    Component.onCompleted: {
        if (Genivi.preloadMode==true)
        {
            Genivi.preloadMode=false;
            loadWithAddress();
        }
    }
}
