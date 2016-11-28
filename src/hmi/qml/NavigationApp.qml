/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2017, PSA GROUPE
*
* \file NavigationApp.qml
*
* \brief This file is part of the navigation hmi.
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
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
* <date>, <name>, <description of change>
*
* @licence end@
*/
import QtQuick 2.1 
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/NavigationAppBrowseMap-css.js" as StyleSheetMap;
import "Core/genivi.js" as Genivi;

ApplicationWindow {
	id: container
    visible: true
    width: StyleSheetMap.menu[Constants.WIDTH];
    height: StyleSheetMap.menu[Constants.HEIGHT];
	property Item component;
	function load(page)
	{
		if (component) {
			component.destroy();
		}
		component = Qt.createQmlObject(page+"{}",container,"dynamic");
	}

	Component.onCompleted: {
        Genivi.setlang("eng_USA"); //by default set to english US
        load("NavigationAppMain");
	}
}
