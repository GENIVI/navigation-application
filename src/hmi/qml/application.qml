/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file MainMenu.qml
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
* 2014-03-05, Philippe Colliot, set the language by default
* <date>, <name>, <description of change>
*
* @licence end@
*/
import QtQuick 2.1 
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/navigation-browse-map-css.js" as StyleSheetMap;
import "Core/genivi.js" as Genivi;

ApplicationWindow {
	id: container
	visible: true
    width: StyleSheetMap.menu[Constants.WIDTH];
    height: StyleSheetMap.menu[Constants.HEIGHT];
    property Item layer_manager;
    property Item layer_number;
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
        if (layer_manager)
        {
            Genivi.g_layer_manager = true;
            Genivi.g_layer = layer_number;
        }
		load("MainMenu");
	}
}
