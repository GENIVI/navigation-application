/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file EntryField.qml
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
* 2014-03-05, Philippe Colliot, remove text title from the entry field
* <date>, <name>, <description of change>
*
* @licence end@
*/
import QtQuick 2.1 

import "genivi.js" as Genivi;

Column {
    id: entryfield
    width: input.width
    height: input.height
    property alias text: input.text
	property alias criterion: input.criterion
	property alias textfocus: input.focus
	property alias next: input.next
	property alias prev: input.prev
	property string globaldata
	property bool disabled
	signal leave()
	opacity: disabled ? 0.2 : 1

	function takeFocus()
	{
		input.forceActiveFocus();
	}

	function callEntry()
	{
		entryfield.leave();
		Genivi.entrydest=globaldata;
		Genivi.entrycriterion=criterion;
        if (criterion && criterion != Genivi.NAVIGATIONCORE_FULL_ADDRESS) {
            keyboardArea.destination = this;
            input.text = "";
		} else {
            //to do
		}
	}

    Rectangle {
        width: parent.width; height: parent.height; color: 'transparent'
        Row {
            width: parent.width; height: parent.height;
			TextInput {
                property real criterion
				property Item next
				property Item prev
				signal mclicked()
                id:input; width: parent.width*3/4; height: parent.height; color: 'white'; font.pixelSize: parent.height*0.75
				onMclicked: { callEntry(); }
                text: Genivi.data[globaldata]?Genivi.data[globaldata]:""
                wrapMode: Text.WordWrap
                clip: true
                MouseArea {
					anchors.fill: parent
					onClicked: {
						if (!entryfield.disabled) {
							if (!input.focus) {
								takeFocus();
							} else {
								callEntry();
							}
						}
					}
				}
				Keys.onReturnPressed: {
					accept(entryfield);
				}
			}
		}
	}
}
