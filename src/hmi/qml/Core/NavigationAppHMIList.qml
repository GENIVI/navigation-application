/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
*
* \file NavigationAppHMIList.qml
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

Rectangle {
	id:rectangle
	property alias delegate: view.delegate
	property alias model: view.model
	property alias next: view.next
	property alias prev: view.prev
	signal selected(variant what)
	color: "#141414"

	function takeFocus(dir) {
		view.takeFocus(dir);
	}

	ListView {
		id:view
		property Item prev
		property Item next
		property Item prevsave
		property Item nextsave
		highlightFollowsCurrentItem:false
		property bool hasFocus:false
		// interactive:false
		signal mclicked()
		anchors.fill: parent
		model: ListModel{}
		highlight: Rectangle { color: "lightsteelblue"; radius: 5 }
		clip: true

		onMclicked: {
			rectangle.selected(view.currentItem);
		}
		MouseArea {
			anchors.fill: parent
			onPressed: {
				view.highlightFollowsCurrentItem=true;
				view.currentIndex=view.indexAt(view.contentX+mouse.x,view.contentY+mouse.y);
			}
			onCanceled: {
				view.currentIndex=-1;
			}
			onClicked: {
				view.currentIndex=view.indexAt(view.contentX+mouse.x,view.contentY+mouse.y);
				rectangle.selected(view.currentItem);
			}
		}
		function takeFocus(dir) {
			var max=view.model.count-1;
			if (!hasFocus) {
				forceActiveFocus();
				hasFocus=true;	
				nextsave=next;
				prevsave=prev;
				next=view;
				prev=view;
				highlightFollowsCurrentItem=true;
				if (dir > 0) {
					view.positionViewAtBeginning();
					currentIndex=0;
				} else {
					view.positionViewAtEnd();
					currentIndex=max;
				}
				return;
			}
			prev=view;
			next=view;
			if (dir > 0) {
				if (currentIndex < max) {
					currentIndex++;	
					return;
				}
			} else {
				if (currentIndex > 0) {
					currentIndex--;	
					return;
				}
			}
			hasFocus=false;
			highlightFollowsCurrentItem=false;
			next=nextsave;
			prev=prevsave;
			if (dir > 0)
				menu.focus_next();
			else
				menu.focus_prev();
		}

		function giveFocus() {
			currentIndex=-1;
		}
	}
}

