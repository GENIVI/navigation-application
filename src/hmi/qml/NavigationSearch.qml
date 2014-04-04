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

HMIMenu {
    id: menu
    text: Genivi.gettext("NavigationSearch")
    next: address
    prev: back
    headlineFg: "grey"
    headlineBg: "blue"
    DBusIf {
        id:dbusIf;
    }

    HMIBgImage {
        image:"navigation-search-menu-background";
        anchors { fill: parent; topMargin: parent.headlineHeight}
        //Important notice: x,y coordinates from the left/top origin of the component
        //so take in account the header height and substract it

        Text {
                height:menu.hspc
                x:274; y:148;
                font.pixelSize: 38;
                style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true
                text: Genivi.gettext("SearchMode")
             }

        StdButton { source:"Core/images/search-by-address.png"; x:100; y:30; width:140; height:100;id:address;  explode:false; next:coordinates; prev:back;
            onClicked: {
                Genivi.preloadMode=true;
                pageOpen("NavigationSearchAddress");
            }
        }
        StdButton { source:"Core/images/search-by-coordinates.png"; x:560; y:30; width:140; height:100;id:coordinates; page:"NavigationSearchCoordinates"; explode:false; next:poi; prev:address}
        StdButton { source:"Core/images/search-by-poi.png"; x:100; y:224; width:140; height:100;id:poi; page:"POI"; explode:false; next:free; prev:coordinates}
        StdButton { source:"Core/images/search-by-freetext.png"; x:560; y:224; width:140; height:100;id:free; page:"NavigationSearchFreeText"; explode:false; next:back; prev:poi}

        StdButton { textColor:"black"; pixelSize:38 ; source:"Core/images/history.png"; x:20; y:374; width:260; height:60; id:preferences; text: Genivi.gettext("History"); disabled:false; explode:false; next:back; prev:free; page:"NavigationSearchHistory"}

        StdButton { textColor:"black"; pixelSize:38 ;source:"Core/images/back.png"; x:600; y:374; width:180; height:60;id:back; text: Genivi.gettext("Back"); explode:false; next:address; prev:free; page:"MainMenu";}
    }
}
