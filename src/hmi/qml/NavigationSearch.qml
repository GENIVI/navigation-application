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
import QtQuick 1.0
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/navigation-search-menu-css.js" as StyleSheet;

HMIMenu {
    id: menu
    text: Genivi.gettext("NavigationSearch")
    next: search_by_address
    prev: back
    headlineFg: "grey"
    headlineBg: "blue"
    DBusIf {
        id:dbusIf;
    }

    HMIBgImage {
        image:StyleSheet.navigation_search_menu_background[StyleSheet.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

        Text {
            x:StyleSheet.searchTitle[StyleSheet.X]; y:StyleSheet.searchTitle[StyleSheet.Y]; width:StyleSheet.searchTitle[StyleSheet.WIDTH]; height:StyleSheet.searchTitle[StyleSheet.HEIGHT];color:StyleSheet.searchTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.searchTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.searchTitle[StyleSheet.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            id: searchTitle
            text: Genivi.gettext("SearchMode")
        }

        StdButton { source:StyleSheet.search_by_address[StyleSheet.SOURCE]; x:StyleSheet.search_by_address[StyleSheet.X]; y:StyleSheet.search_by_address[StyleSheet.Y]; width:StyleSheet.search_by_address[StyleSheet.WIDTH]; height:StyleSheet.search_by_address[StyleSheet.HEIGHT];
            id:search_by_address;  explode:false; next:search_by_coordinates; prev:back;
            onClicked: {
                Genivi.preloadMode=true;
                pageOpen("NavigationSearchAddress");
            }
        }
        StdButton { source:StyleSheet.search_by_coordinates[StyleSheet.SOURCE]; x:StyleSheet.search_by_coordinates[StyleSheet.X]; y:StyleSheet.search_by_coordinates[StyleSheet.Y]; width:StyleSheet.search_by_coordinates[StyleSheet.WIDTH]; height:StyleSheet.search_by_coordinates[StyleSheet.HEIGHT];
            id:search_by_coordinates; page:"NavigationSearchCoordinates"; explode:false; next:search_by_poi; prev:search_by_address}
        StdButton { source:StyleSheet.search_by_poi[StyleSheet.SOURCE]; x:StyleSheet.search_by_poi[StyleSheet.X]; y:StyleSheet.search_by_poi[StyleSheet.Y]; width:StyleSheet.search_by_poi[StyleSheet.WIDTH]; height:StyleSheet.search_by_poi[StyleSheet.HEIGHT];
            id:search_by_poi; page:"POI"; explode:false; next:search_by_freetext; prev:search_by_coordinates}
        StdButton { source:StyleSheet.search_by_freetext[StyleSheet.SOURCE]; x:StyleSheet.search_by_freetext[StyleSheet.X]; y:StyleSheet.search_by_freetext[StyleSheet.Y]; width:StyleSheet.search_by_freetext[StyleSheet.WIDTH]; height:StyleSheet.search_by_freetext[StyleSheet.HEIGHT];
            id:search_by_freetext; page:"NavigationSearchFreeText"; explode:false; next:history; prev:search_by_poi}

        StdButton { source:StyleSheet.history[StyleSheet.SOURCE]; x:StyleSheet.history[StyleSheet.X]; y:StyleSheet.history[StyleSheet.Y]; width:StyleSheet.history[StyleSheet.WIDTH]; height:StyleSheet.history[StyleSheet.HEIGHT];textColor:StyleSheet.historyText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.historyText[StyleSheet.PIXELSIZE];
            id:history; text: Genivi.gettext("History"); disabled:false; explode:false; next:back; prev:search_by_freetext; page:"NavigationSearchHistory"}

        StdButton { source:StyleSheet.back[StyleSheet.SOURCE]; x:StyleSheet.back[StyleSheet.X]; y:StyleSheet.back[StyleSheet.Y]; width:StyleSheet.back[StyleSheet.WIDTH]; height:StyleSheet.back[StyleSheet.HEIGHT];textColor:StyleSheet.backText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.backText[StyleSheet.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); explode:false; next:search_by_address; prev:search_by_freetext; page:"MainMenu";}
    }
}
