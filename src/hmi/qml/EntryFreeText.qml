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
    property string pagefile:"EntryFreeText"

    color: Constants.MENU_BACKGROUND_COLOR

    //property Item currentSelectionCriterionSignal;
    property Item searchStatusSignal;
    property Item searchResultListSignal;
    //property Item contentUpdatedSignal;
	property real criterion;

	DBusIf {
                id:dbusIf
        }

	function searchStatus(args)
	{
		if (args[3] == Genivi.NAVIGATIONCORE_SEARCHING) {
            viewListAddress.model.clear();
            viewListPOI.model.clear();
            text.color='red';  //(Searching)
		} else
            text.color='white';
	}

    function searchResultListAddress(args)
	{
        var model=viewListAddress.model;
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

    function search(input)
	{
        Genivi.locationinput_message(dbusIf,"Search",["string",input,"uint16",10]);
	}

	function connectSignals()
	{
		//currentSelectionCriterionSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","CurrentSelectionCriterion",menu,"currentSelectionCriterion");
		searchStatusSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","SearchStatus",menu,"searchStatus");
        searchResultListSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","SearchResultList",menu,"searchResultListAddress");
		//contentUpdatedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.LocationInput","ContentUpdated",menu,"contentUpdated");
	}
	
	function disconnectSignals()
	{
		//currentSelectionCriterionSignal.destroy();
		searchStatusSignal.destroy();
		searchResultListSignal.destroy();
		//contentUpdatedSignal.destroy();
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
            search(event.text);
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
            } next:viewListAddress; prev:keyboard}
		}

        Component {
            id: listDelegateAddress
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

        Column {
            width:parent.width/2;
            height:parent.height-keyboard.height-textrow.height;
            HMIList {
                id:viewListAddress
                property real selectedEntry
                height:parent.height;
                width:parent.width;
                delegate: listDelegateAddress
                next:keyboard
                prev:back
                onSelected:{
                    Genivi.entrydest=null;
                    disconnectSignals();
                    Genivi.entryselectedentry=what.index;
                    leaveMenu();
                }
            }
        }

        Component {
            id: listDelegatePOI
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

        Column {
            HMIList {
                id:viewListPOI
                property real selectedEntry
                height:parent.height-keyboard.height-textrow.height;
                width:parent.width/2;
                delegate: listDelegatePOI
                next:keyboard
                prev:viewListAddress
                onSelected:{
                    Genivi.entrydest=null;
                    disconnectSignals();
                    Genivi.entryselectedentry=what.index;
                    leaveMenu();
                }
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
            prev: viewListAddress;
            onKeypress: { search(what); }
		}
	}

    Component.onCompleted: {
        viewListAddress.forceActiveFocus();
		if (Genivi.entrycriterion) {
			criterion=Genivi.entrycriterion;
			Genivi.entrycriterion=0;	
			Genivi.locationinput_message(dbusIf,"SetSelectionCriterion",["uint16",criterion]);
		}
		connectSignals();
	}
}
