/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
*
* \file Entry.qml
*
* \brief This file is part of the navigation hmi.
*
* \author Martin Schaller <martin.schaller@it-schaller.de>
*
* \version 
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
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    property string pagefile:"Entry"

    color: Constants.MENU_BACKGROUND_COLOR

    //property Item currentSelectionCriterionSignal;
    property Item searchStatusSignal;
    property Item searchResultListSignal;
    //property Item contentUpdatedSignal;
	property Item spellResultSignal;
	property real criterion;
	property string extraspell;

	DBusIf {
                id:dbusIf
        }

	function searchStatus(args)
    { //locationInputHandle 1, statusValue 3
        var statusValue=args[3];
        if (statusValue == Genivi.NAVIGATIONCORE_SEARCHING) {
			view.model.clear();
            text.color='red';  //(Searching)
        } else {
            if (statusValue == Genivi.NAVIGATIONCORE_FINISHED)
            {
                text.color='white';
                Genivi.locationInput_RequestListUpdate(dbusIf,0,10);
            }
        }
	}

	function searchResultList(args)
    {//locationInputHandle 1, totalSize 3, windowOffset 5, windowSize 7, resultListWindow 9
		var model=view.model;
        var windowOffset=args[5];
        var resultListWindow=args[9];
        var offset=args[5];
        var array=args[9];
        for (var i=0 ; i < resultListWindow.length ; i+=2) {
            for (var j = 0 ; j < resultListWindow[i+1].length ; j+=4) {
                if (resultListWindow[i+1][j+1] == criterion) {
                    model.append({"name":resultListWindow[i+1][j+3][3][1],"number":(i/2)+windowOffset+1});
                }
            }
        }
	}

	function spellResult(args)
    {//locationInputHandle 1, uniqueString 3, validCharacters 5, fullMatch 7
        var uniqueString=args[3];
        var validCharacters=args[5];
        if (text.text.length < uniqueString.length) {
            extraspell=uniqueString.substr(text.text.length);
            text.text=uniqueString;
        }
        keyboard.setactivekeys('\b'+validCharacters,true);
	}

	function spell(input)
	{
		input=extraspell+input;
		extraspell='';
        Genivi.locationInput_Spell(dbusIf,input,10);
	}

	function connectSignals()
	{
		//currentSelectionCriterionSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","CurrentSelectionCriterion",menu,"currentSelectionCriterion");
		searchStatusSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","SearchStatus",menu,"searchStatus");
		searchResultListSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","SearchResultList",menu,"searchResultList");
		//contentUpdatedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","ContentUpdated",menu,"contentUpdated");
		spellResultSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","SpellResult",menu,"spellResult");
	}
	
	function disconnectSignals()
	{
		//currentSelectionCriterionSignal.destroy();
		searchStatusSignal.destroy();
		searchResultListSignal.destroy();
		//contentUpdatedSignal.destroy();
		spellResultSignal.destroy();
	}

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
	Column {
		id:content
		anchors { fill: parent; topMargin: menu.hspc/2 }
		Row {
			id:textrow
			spacing:menu.hspc/4;
			anchors.topMargin: 100;
			Rectangle {
				color:'black';
                width:content.width-back.width-menu.hspc/4-menu.hspc/8;
				height:back.height;
				Text {
					anchors.fill:parent;
					id: text
					font.pixelSize: 40;
					color: "white"; smooth: true
					focus: true
				}
			}
			StdButton { id:back; text: "Back"; onClicked: {
				disconnectSignals();
                Genivi.entrycancel=true;
                Genivi.preloadMode=true;
                leaveMenu();
			} next:view; prev:keyboard}
		}

		Component {
			id: listDelegate
			Text {
				property real index:number;
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
			property real selectedEntry
			height:parent.height-keyboard.height-textrow.height;
			width:parent.width;
			id:view
			delegate: listDelegate
			next:keyboard
			prev:back
			onSelected:{
				Genivi.entrydest=null;
				disconnectSignals();
				Genivi.entryselectedentry=what.index;
                leaveMenu();
			}
		}

		Keyboard {
			id: keyboard
			height: 200;
			width: menu.width;
			destination: text;
			firstLayout: "ABC";
			secondLayout: "abc";
			next: back;
			prev: view;
			onKeypress: { spell(what); }
		}
	}
	Component.onCompleted: {
		view.forceActiveFocus();
        if (Genivi.entrycriterion) {
            criterion=Genivi.entrycriterion;
            Genivi.entrycriterion=0;
            Genivi.locationInput_SetSelectionCriterion(dbusIf,criterion);
        }
        extraspell='';
        if(criterion != Genivi.NAVIGATIONCORE_STREET)
        {
            spell('');
        }

        connectSignals();
	}
}
