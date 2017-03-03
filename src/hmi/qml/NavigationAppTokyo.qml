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
import lbs.plugin.dbusif 1.0

ApplicationWindow {
	id: container
    flags: Qt.FramelessWindowHint
    color: "transparent"
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

    //------------------------------------------//
    // Management of the DBus exchanges
    //------------------------------------------//
    DBusIf {
        id:dbusIf;
    }

	Component.onCompleted: {
        Genivi.setlang("jpn","JPN","Hrkt"); //set to japanese
        Genivi.setDefaultPosition(35.758795,139.316533,19); // (1 Chome-1-5 Gonokami Hamura-shi, Tōkyō-to)
        Genivi.setDefaultAddress("Japan","東京","井ノ頭通り","17"); // preferred address
        Genivi.navigationcore_configuration_SetLocale(dbusIf,Genivi.g_language,Genivi.g_country,Genivi.g_script);
        load("NavigationAppMain");
	}
}
