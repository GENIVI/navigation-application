/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file KButton.qml
*
* \brief This file is part of the navigation hmi.
*
* \author Martin Schaller <martin.schaller@it-schaller.de>
* \author Philippe Colliot <philippe.colliot@mpsa.com>
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
* 2014-03-05, Philippe Colliot, change of the background image
* <date>, <name>, <description of change>
*
* @licence end@
*/
import QtQuick 2.1 


Button {
	id: button
    source:"../../images/button-keyboard.png";
	width: keyboard.w
	height: keyboard.h
	pixelSize: 20
	explode: false
	property bool special: false

	onClicked: {
		if (!special) {
			keyboard.append(what.text);
		}
	}
}
