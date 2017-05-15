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
import "../style-sheets/style-constants.js" as Constants;
import "../style-sheets/NavigationAppBrowseMap-css.js" as StyleSheetMap;
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
        //set persistent data
        Genivi.setlang("eng","USA","Latn"); //set to english US
        Genivi.setDefaultPosition(46.202038,6.146845,392); // (rue Jean Calvin Genève)
        Genivi.setDefaultAddress("Switzerland","Lausanne","Rue de Midi","8"); // preferred address

        //configure the middleware
        Genivi.navigationcore_configuration_SetLocale(dbusIf,Genivi.g_language,Genivi.g_country,Genivi.g_script);

        //launch the map viewer and init the scale list
        Genivi.mapviewer_handle(dbusIf,width,height,Genivi.MAPVIEWER_MAIN_MAP);
        Genivi.initScale(dbusIf);

        //set verbose mode on
        Genivi.setVerbose();

        //launch the HMI
        load("NavigationAppMain");
	}

    Component.onDestruction:  {
        //release the map viewer
        Genivi.mapviewer_handle_clear(dbusIf);
    }
}
