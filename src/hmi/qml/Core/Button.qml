/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
*
* \file Button.qml
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


BorderImage {
	id: button

	property alias text: buttonText.text 
	property alias textColor: buttonText.color
	property string color: ""
	property variant userdata
	property bool disabled
	property bool explode: true
	property Item next
	property Item prev
	property real pixelSize: 0
	property real fontScale: 1
	
	
	KeyNavigation.tab:next
	KeyNavigation.backtab:prev

	signal clicked(variant what)
	signal mclicked()
	signal pressed;
	signal released;

	source: "images/button-" + color + ".png"; clip: true 
	opacity: disabled ? 0.2 : 1

	Keys.onBacktabPressed:{menu.focus_prev();}

	Keys.onTabPressed:{menu.focus_next();}

	onMclicked: { clicked(button); }


	border {
		left: 10; top: 10; right: 10; bottom: 10
	}

	Rectangle {
		id: shade
		anchors.fill: button; radius: 10; color: "black"; opacity: 0
	}

	Text {
		id: buttonText
		anchors.centerIn: parent; anchors.verticalCenterOffset: -1
		font.pixelSize: parent.pixelSize ? parent.pixelSize : (parent.width > parent.height ? parent.height * .20 : parent.width * .15)*parent.fontScale;
		style: Text.Sunken; color: "white"; styleColor: "black"; smooth: true
	}

	MouseArea {
		id: mouseArea
		anchors.fill: parent
		onClicked: {
			if (!button.disabled) {
				if (button.explode) {
					button.state='selected';
				}
				button.clicked(button);
			}
		}
		onPressed: button.pressed();
		onReleased: button.released();
	}

	states: [
		State {
			name: "pressed"; when: mouseArea.pressed == true && !button.disabled
			PropertyChanges { target: shade; opacity: .4 }
			PropertyChanges { target: button; scale: 1.2 }
		},
		State {
			name: "selected"
			PropertyChanges { target: button; opacity: 0 }
			PropertyChanges { target: button; scale: 4 }
		},
		State {
			when: focus
			PropertyChanges { target: shade; opacity: .4 }
			PropertyChanges { target: button; scale: 1.2 }
		}
	]
	transitions: Transition {
		NumberAnimation { properties: "scale"; easing.type: "OutExpo"; duration: 200 }
		NumberAnimation { properties: "opacity"; easing.type: "InQuad"; duration: 200 }
	}
}
