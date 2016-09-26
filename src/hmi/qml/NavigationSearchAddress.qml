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
import QtQuick 2.1 
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/navigation-search-address-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
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
            countryValue.text=Genivi.address[Genivi.NAVIGATIONCORE_COUNTRY];
            accept(countryValue);
            cityValue.disabled=false;
            if (Genivi.address[Genivi.NAVIGATIONCORE_CITY] !== "")
            {
                cityValue.text=Genivi.address[Genivi.NAVIGATIONCORE_CITY];
                accept(cityValue);
                streetValue.disabled=false;
                if (Genivi.address[Genivi.NAVIGATIONCORE_STREET] !== "")
                {
                    streetValue.text=Genivi.address[Genivi.NAVIGATIONCORE_STREET];
                    accept(streetValue);
                    numberValue.disabled=false;
                }
            }
        }
    }

	function currentSelectionCriterion(args)
    {// locationInputHandle 1, selectionCriterion 3
        var selectionCriterion=args[3];
        Genivi.entrycriterion = selectionCriterion;
	}

	function searchStatus(args)
    { //locationInputHandle 1, statusValue 3
        var statusValue=args[3];
        Genivi.dump("searchStatus",args);
        if (statusValue === Genivi.NAVIGATIONCORE_FINISHED)
        {
            Genivi.locationinput_SelectEntry(dbusIf,Genivi.entryselectedentry);
        }
    }

	function searchResultList(args)
	{
	}

	function contentUpdated(args)
    { //locationInputHandle 1, guidable 3, availableSelectionCriteria 5, address 7

        // Check if the destination is guidable
        var guidable=args[3];
        if (guidable) {
            ok.disabled=false;
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
		ok.disabled=true;
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

    HMIBgImage {
        image:StyleSheet.navigation_search_by_address_menu_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}
        id: content

        Text {
            x:StyleSheet.countryTitle[Constants.X]; y:StyleSheet.countryTitle[Constants.Y]; width:StyleSheet.countryTitle[Constants.WIDTH]; height:StyleSheet.countryTitle[Constants.HEIGHT];color:StyleSheet.countryTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.countryTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.countryTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true;
            id: countryTitle
            text: Genivi.gettext("Country");
        }
        EntryField {
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
            x:StyleSheet.streetTitle[Constants.X]; y:StyleSheet.streetTitle[Constants.Y]; width:StyleSheet.streetTitle[Constants.WIDTH]; height:StyleSheet.streetTitle[Constants.HEIGHT];color:StyleSheet.streetTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.streetTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.streetTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true;
            id:streetTitle
            text: Genivi.gettext("Street");
        }
		EntryField {
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
            x:StyleSheet.cityTitle[Constants.X]; y:StyleSheet.cityTitle[Constants.Y]; width:StyleSheet.cityTitle[Constants.WIDTH]; height:StyleSheet.cityTitle[Constants.HEIGHT];color:StyleSheet.cityTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.cityTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.cityTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true;
            id:cityTitle
            text: Genivi.gettext("City");
        }
        EntryField {
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
            x:StyleSheet.numberTitle[Constants.X]; y:StyleSheet.numberTitle[Constants.Y]; width:StyleSheet.numberTitle[Constants.WIDTH]; height:StyleSheet.numberTitle[Constants.HEIGHT];color:StyleSheet.numberTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.numberTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.numberTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true;
            id:numberTitle
            text: Genivi.gettext("Number");
        }
        EntryField {
            x:StyleSheet.numberValue[Constants.X]; y:StyleSheet.numberValue[Constants.Y]; width: StyleSheet.numberValue[Constants.WIDTH]; height: StyleSheet.numberValue[Constants.HEIGHT];
            id:numberValue
			criterion: Genivi.NAVIGATIONCORE_HOUSENUMBER
            globaldata: 'numberValue'
			next: ok
            prev: streetValue
			disabled: true
			onLeave:{menu.leave(0)}
		}

        StdButton { source:StyleSheet.ok[Constants.SOURCE]; x:StyleSheet.ok[Constants.X]; y:StyleSheet.ok[Constants.Y]; width:StyleSheet.ok[Constants.WIDTH]; height:StyleSheet.ok[Constants.HEIGHT];textColor:StyleSheet.okText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.okText[Constants.PIXELSIZE];
            id:ok
            next:back
            prev:numberValue
            text:Genivi.gettext("Ok")
            disabled: true
            onClicked:{
                leave(1);
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
                routeMenu();
            }
        }

        StdButton { source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); explode:false; next:countryValue; prev:ok;
            onClicked:{leave(1); leaveMenu();}
        }
	}
    Component.onCompleted: {
        connectSignals();

        var res=Genivi.navigationcore_session_GetVersion(dbusIf);
        if (res[0] != "error") {
            res=Genivi.navigationcore_session(dbusIf);
            res=Genivi.locationinput_handle(dbusIf);
        } else {
            Genivi.dump("",res);
        }
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
            Genivi.preloadMode=false;
            loadWithAddress();
        }
    }
}
