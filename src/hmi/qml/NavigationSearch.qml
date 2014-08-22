/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationSearch.qml
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
* 2014-03-05, Philippe Colliot, migration to the new HMI design
* <date>, <name>, <description of change>
*
* @licence end@
*/
import QtQuick 2.1 
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/navigation-search-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
    id: menu
    next: search_by_address
    prev: back
    DBusIf {
        id:dbusIf;
    }

    HMIBgImage {
        image:StyleSheet.navigation_search_menu_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

        Text {
            x:StyleSheet.searchTitle[Constants.X]; y:StyleSheet.searchTitle[Constants.Y]; width:StyleSheet.searchTitle[Constants.WIDTH]; height:StyleSheet.searchTitle[Constants.HEIGHT];color:StyleSheet.searchTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.searchTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.searchTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            id: searchTitle
            text: Genivi.gettext("SearchMode")
        }

        StdButton { source:StyleSheet.search_by_address[Constants.SOURCE]; x:StyleSheet.search_by_address[Constants.X]; y:StyleSheet.search_by_address[Constants.Y]; width:StyleSheet.search_by_address[Constants.WIDTH]; height:StyleSheet.search_by_address[Constants.HEIGHT];
            id:search_by_address;  explode:false; next:search_by_coordinates; prev:back;
            onClicked: {
                Genivi.preloadMode=true;
                pageOpen("NavigationSearchAddress");
            }
        }
        StdButton { source:StyleSheet.search_by_coordinates[Constants.SOURCE]; x:StyleSheet.search_by_coordinates[Constants.X]; y:StyleSheet.search_by_coordinates[Constants.Y]; width:StyleSheet.search_by_coordinates[Constants.WIDTH]; height:StyleSheet.search_by_coordinates[Constants.HEIGHT];
            id:search_by_coordinates; page:"NavigationSearchCoordinates"; explode:false; next:search_by_poi; prev:search_by_address}
        StdButton { source:StyleSheet.search_by_poi[Constants.SOURCE]; x:StyleSheet.search_by_poi[Constants.X]; y:StyleSheet.search_by_poi[Constants.Y]; width:StyleSheet.search_by_poi[Constants.WIDTH]; height:StyleSheet.search_by_poi[Constants.HEIGHT];
            id:search_by_poi; page:"POI"; explode:false; next:search_by_freetext; prev:search_by_coordinates}
        StdButton { source:StyleSheet.search_by_freetext[Constants.SOURCE]; x:StyleSheet.search_by_freetext[Constants.X]; y:StyleSheet.search_by_freetext[Constants.Y]; width:StyleSheet.search_by_freetext[Constants.WIDTH]; height:StyleSheet.search_by_freetext[Constants.HEIGHT];
            id:search_by_freetext; page:"NavigationSearchFreeText"; explode:false; next:history; prev:search_by_poi}

        StdButton { source:StyleSheet.history[Constants.SOURCE]; x:StyleSheet.history[Constants.X]; y:StyleSheet.history[Constants.Y]; width:StyleSheet.history[Constants.WIDTH]; height:StyleSheet.history[Constants.HEIGHT];textColor:StyleSheet.historyText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.historyText[Constants.PIXELSIZE];
            id:history; text: Genivi.gettext("History"); disabled:false; explode:false; next:back; prev:search_by_freetext; page:"NavigationSearchHistory"}

        StdButton { source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); explode:false; next:search_by_address; prev:search_by_freetext; page:"MainMenu";}
    }
}
