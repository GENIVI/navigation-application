/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
*
* \file NavigationAppHMIBgImage.qml
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
* 2014-05-08, Philippe Colliot, use of css file so change path of the image
* <date>, <name>, <description of change>
*
* @licence end@
*/
import QtQuick 2.1 

BorderImage {
	property string image;
	source:"../"+image;
	anchors { fill: parent; topMargin: parent.headlineHeight}
}
