/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
*
* \file EntrySimple.qml
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
    color: Constants.MENU_BACKGROUND_COLOR
	DBusIf {
                id:dbusIf
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
				width:content.width-back.width-ok.width-menu.hspc/2-menu.hspc/8;
				height:back.height;
				Text {
					anchors.fill:parent;
					id: text
					font.pixelSize: 40;
					color: "white"; smooth: true
					focus: true
				}
			}
			StdButton { id:ok; text: "Ok"; onClicked: {
				Genivi.data[Genivi.entrydest]=text.text;
				pageOpen(Genivi.entryback);
			} next:back; prev:keyboard}
			StdButton { id:back; text: "Back"; onClicked: {
				Genivi.entrydest=null;
				pageOpen(Genivi.entryback);
			} next:keyboard; prev:ok}
		}
		Row {
			height:parent.height-keyboard.height-textrow.height;
                        width:parent.width;
		}

		Keyboard {
			id: keyboard
			height: 200;
			width: menu.width;
			destination: text;
			firstLayout: "ABC";
			secondLayout: "abc";
			next: back;
			prev: ok;
			onKeypress: { }
		}
	}
}
