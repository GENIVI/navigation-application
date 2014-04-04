/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file Navigation.qml
*
* \brief This file is part of the FSA HMI.
*
* \author Martin Schaller <martin.schaller@it-schaller.de>
*
* \version 1.0
*
* This Source Code Form is subject to the terms of the
* Mozilla Public License (MPL), v. 2.0.
* If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/.
*
* For further information see http://www.genivi.org/.
*
* List of changes:
* 
* <date>, <name>, <description of change>
*
* @licence end@
*/
import QtQuick 1.0
import "Core"
import "Core/genivi.js" as Genivi;

HMIMenu {
	id: menu
	text: "Navigation"
	next: back
	prev: search
	HMIGrid {
		id: content
		rows: 2
		columns: 2
		StdButton { id:back; text:"Back"; page:"MainMenu"; next:search; prev:back}
		StdButton { id:search; text:"Search"; page:"NavigationSearch"; next:settings; prev:back}
		StdButton { id:settings; text:"Settings"; page:"NavigationSettings"; next:browse; prev:search }
		StdButton { id:browse; text:"Browse Map"; next:back; prev:settings
			onClicked: {
				Genivi.data["mapback"]="Navigation";
				Genivi.data["show_current_position"]=true;
				pageOpen("NavigationBrowseMap");
			}
		}
	}
}
