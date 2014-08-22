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
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu

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
	{
		if (args[3] == Genivi.NAVIGATIONCORE_SEARCHING) {
			view.model.clear();
            text.color='red';  //(Searching)
		} else
            text.color='white';
	}

	function searchResultList(args)
	{
		var model=view.model;
		if (args[4] == "uint16" && args[8] == "array") {
			var offset=args[5];
			var array=args[9];
			for (var i=0 ; i < array.length ; i+=2) {
				if (array[i] == "map") {
					var map=array[i+1];
					for (var j = 0 ; j < map.length ; j+=4) {
						if (map[j] == "uint16" && map[j+1] == criterion) {
							if (map[j+2] == "variant") {
								var variant=map[j+3];
								if (variant[0] == "string") {
									model.append({"name":variant[1],"number":(i/2)+offset+1});
								}
							}
						}
					}
				}
			}
		} else {
			console.log("Unexpected result from SearchResultList:");
			Genivi.dump("",args);
		}
	}

	function spellResult(args)
	{
		if (args[0] == "uint32" && args[2] == "string" && args[4] == "string") {
			if (text.text.length < args[3].length) {
				extraspell=args[3].substr(text.text.length);
				text.text=args[3];
				
			}
			keyboard.setactivekeys('\b'+args[5],true);
		} else {
			console.log("Unexpected result from SpellResult:");
		}
	}

	function spell(input)
	{
		input=extraspell+input;
		extraspell='';
		Genivi.locationinput_message(dbusIf,"Spell",["string",input,"uint16",10]);
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
/*
			StdButton { id:ok; text: "Ok"; onClicked: {
				Genivi.data[Genivi.entrydest]=text.text;
				disconnectSignals();
				pageOpen(Genivi.entryback);
			} next:back; prev:view}
*/
			StdButton { id:back; text: "Back"; onClicked: {
				Genivi.entrydest=null;
				disconnectSignals();
                Genivi.entryselectedentry=0;
				pageOpen(Genivi.entryback);
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
				pageOpen(Genivi.entryback);
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
			Genivi.locationinput_message(dbusIf,"SetSelectionCriterion",["uint16",criterion]);
		}
		connectSignals();
	}
}
