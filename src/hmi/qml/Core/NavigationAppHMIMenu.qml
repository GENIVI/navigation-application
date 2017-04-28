/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
*
* \file HMIMenu.qml
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
import "genivi.js" as Genivi;
import "../../style-sheets/style-constants.js" as Constants;
import lbs.plugin.wheelarea 1.0

Rectangle {
	id: menu
    property alias loader: pageLoader
    property string pageBack
	property Item next
	property Item prev
    color: "transparent"
	focus: true
	anchors.fill: parent

	KeyNavigation.tab:next
	KeyNavigation.backtab:prev

	MouseArea {
		acceptedButtons: Qt.MiddleButton
		anchors.fill: parent
		onClicked: {
			var focus=find_focus(menu);
			focus.mclicked(focus);
		}

	}

	function focus_next()
	{
		var focus=find_focus(menu);
		if (focus.next != focus && focus.giveFocus)
			focus.giveFocus();
		do {
			focus=focus.next;
		} while (focus.disabled);
		if (focus.takeFocus) {
			focus.takeFocus(1);
		} else {
			focus.forceActiveFocus();
		}
	}

	function focus_prev()
	{
		var focus=find_focus(menu);
		if (focus.prev != focus && focus.giveFocus)
			focus.giveFocus();
		do {
			focus=focus.prev;
		} while (focus.disabled);
		if (focus.takeFocus) {
			focus.takeFocus(-1);
		} else {
			focus.forceActiveFocus();
		}
	}

	Keys.onBacktabPressed:{focus_prev();}

	Keys.onTabPressed:{focus_next();}

	WheelArea {
		property real deltasum;
		property real step: 120;
		property real dir: 1;
		anchors.fill: parent
		onWheel: {
			deltasum+=delta*dir;
			//console.log(delta);
			while (deltasum >= step) {
				focus_next();
				deltasum-=step;
			}
			while (deltasum <= -step) {
				focus_prev();
				deltasum+=step;
			}
		}
	}

	property real wspc: 60
	property real hspc: 60

	function w(cols) {
		return ((menu.width - (cols+1)*wspc) / cols);
	}

	function h(rows) {
		return ((menu.height - (rows+1)*hspc) / rows);
	}

	function find_focus(it) {
		//console.log("testing "+it);
		if (it.focus && it.next && it.prev)
			return it;
		for (var i = 0 ; i < it.children.length ; i++) {
			var ret=find_focus(it.children[i]);
			if (ret)
				return ret;
		}
		//console.log("no focus found");
		return null;
	}
			

	Loader {
		id: pageLoader
		states: State {
			name: "visible"
			PropertyChanges { target: pageLoader; opacity: 1 }
		}
		transitions: Transition {
        	        NumberAnimation { properties: "scale"; easing.type: "OutExpo"; duration: 200 }
        	        NumberAnimation { properties: "opacity"; easing.type: "InQuad"; duration: 200 }
        	}
	}

    function entryMenu(inmenu,outmenu)
    {
        Genivi.entrybackheapsize += 1;
        Genivi.entryback[Genivi.entrybackheapsize] = outmenu.pagefile;
        outmenu.state = "hidden";
        container.load(inmenu);
    }

    function leaveMenu()
    {
        var outmenu=Genivi.entryback[Genivi.entrybackheapsize];
        Genivi.entrybackheapsize -= 1;
        menu.state="hidden";
        container.load(outmenu);
    }

	function pageOpen(command) {
        menu.state="hidden";
        container.load(command);
	}

    states: State {
		name: "hidden"
        PropertyChanges { target: parent; opacity: 0 }
	}
	transitions: Transition {
                NumberAnimation { properties: "scale"; easing.type: "OutExpo"; duration: 200 }
                NumberAnimation { properties: "opacity"; easing.type: "InQuad"; duration: 200 }
        }

    Component.onCompleted: {
        if(Genivi.verbose===true){
            console.log("Level: ",Genivi.entrybackheapsize," Menu: ",pagefile);
        }
    }
}
