/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
*
* \file HMIGrid.qml
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

Grid {
	spacing: menu.hspc;
	property real w: menu.w(columns);
	property real h: menu.h(rows);
	anchors { fill: parent; topMargin: menu.hspc; bottomMargin: menu.hspc; leftMargin: menu.wspc; rightMargin: menu.wspc }
}
