/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationRoute.qml
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
import "Core/style-sheets/navigation-route-menu-css.js" as StyleSheet;

HMIMenu {
    id: menu
    headlineFg: "grey"
    headlineBg: "blue"
    text: Genivi.gettext("NavigationRoute")
    next: back
    prev: calculate
    property Item mapmatchedpositionPositionUpdateSignal;

    function latlon_to_map(latlon)
    {
        return [
            "uint16",Genivi.NAVIGATIONCORE_LATITUDE,"variant",["double",latlon['lat']],
            "uint16",Genivi.NAVIGATIONCORE_LONGITUDE,"variant",["double",latlon['lon']]
        ];
    }

    function setLocation()
    {
        locationValue.text=Genivi.data['description'];
        positionValue.text=(Genivi.data['position'] ? Genivi.data['position']['description']:"");
        destinationValue.text=(Genivi.data['destination'] ? Genivi.data['destination']['description']:"");
    }

    function updateCurrentPosition()
    {
        var res=Genivi.nav_message(dbusIf,"MapMatchedPosition","GetPosition",["array",["uint16",Genivi.NAVIGATIONCORE_LATITUDE,"uint16",Genivi.NAVIGATIONCORE_LONGITUDE]]);
        if (res[0] == 'map') {
            var map=res[1];
            var ok=0;
            if (map[0] == 'uint16' && (map[1] == Genivi.NAVIGATIONCORE_LATITUDE || map[1] == Genivi.NAVIGATIONCORE_LONGITUDE) && map[2] == 'variant') {
                var variant=map[3];
                if (variant[0] == 'double' && variant[1] != '0') {
                    ok++;
                }

            }
            if (map[4] == 'uint16' && (map[5] == Genivi.NAVIGATIONCORE_LATITUDE || map[5] == Genivi.NAVIGATIONCORE_LONGITUDE) && map[6] == 'variant') {
                var variant=map[7];
                if (variant[0] == 'double' && variant[1] != '0') {
                    ok++;
                }
            }
            if (ok == 2 && Genivi.data['destination']) {
                calculate_curr.disabled=false;
            } else {
                calculate_curr.disabled=true;
            }
        }

    }

    function mapmatchedpositionPositionUpdate(args)
    {
        updateCurrentPosition();
    }

    function connectSignals()
    {
        mapmatchedpositionPositionUpdateSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.MapMatchedPosition","PositionUpdate",menu,"mapmatchedpositionPositionUpdate");
    }

    function disconnectSignals()
    {
    }

    DBusIf {
        id:dbusIf
    }

    HMIBgImage {
        image:StyleSheet.navigation_route_menu_background[StyleSheet.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

        Text {
            x:StyleSheet.locationTitle[StyleSheet.X]; y:StyleSheet.locationTitle[StyleSheet.Y]; width:StyleSheet.locationTitle[StyleSheet.WIDTH]; height:StyleSheet.locationTitle[StyleSheet.HEIGHT];color:StyleSheet.locationTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.locationTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.locationTitle[StyleSheet.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            id:locationTitle
            text: Genivi.gettext("EnteredLocation")
        }

        Text {
            x:StyleSheet.locationValue[StyleSheet.X]; y:StyleSheet.locationValue[StyleSheet.Y]; width:StyleSheet.locationValue[StyleSheet.WIDTH]; height:StyleSheet.locationValue[StyleSheet.HEIGHT];color:StyleSheet.locationValue[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.locationValue[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.locationValue[StyleSheet.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            wrapMode: Text.WordWrap
            id:locationValue
        }

        Text {
            x:StyleSheet.positionTitle[StyleSheet.X]; y:StyleSheet.positionTitle[StyleSheet.Y]; width:StyleSheet.positionTitle[StyleSheet.WIDTH]; height:StyleSheet.positionTitle[StyleSheet.HEIGHT];color:StyleSheet.positionTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.positionTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.positionTitle[StyleSheet.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            id:positionTitle
            text: Genivi.gettext("Position")
        }

        Text {
            x:StyleSheet.positionValue[StyleSheet.X]; y:StyleSheet.positionValue[StyleSheet.Y]; width:StyleSheet.positionValue[StyleSheet.WIDTH]; height:StyleSheet.positionValue[StyleSheet.HEIGHT];color:StyleSheet.positionValue[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.positionValue[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.positionValue[StyleSheet.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            wrapMode: Text.WordWrap
            id:positionValue
        }

        Text {
            x:StyleSheet.destinationTitle[StyleSheet.X]; y:StyleSheet.destinationTitle[StyleSheet.Y]; width:StyleSheet.destinationTitle[StyleSheet.WIDTH]; height:StyleSheet.destinationTitle[StyleSheet.HEIGHT];color:StyleSheet.destinationTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.destinationTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.destinationTitle[StyleSheet.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            id:destinationTitle
            text: Genivi.gettext("Destination")
        }

        Text {
            x:StyleSheet.destinationValue[StyleSheet.X]; y:StyleSheet.destinationValue[StyleSheet.Y]; width:StyleSheet.destinationValue[StyleSheet.WIDTH]; height:StyleSheet.destinationValue[StyleSheet.HEIGHT];color:StyleSheet.destinationValue[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.destinationValue[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.destinationValue[StyleSheet.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            wrapMode: Text.WordWrap
            id:destinationValue
        }

        StdButton { source:StyleSheet.show_location_on_map[StyleSheet.SOURCE]; x:StyleSheet.show_location_on_map[StyleSheet.X]; y:StyleSheet.show_location_on_map[StyleSheet.Y]; width:StyleSheet.show_location_on_map[StyleSheet.WIDTH]; height:StyleSheet.show_location_on_map[StyleSheet.HEIGHT];
            id:show; disabled:false; next:destination; prev:back; explode:false;
            onClicked: {
                Genivi.data['show_position']=new Array;
                Genivi.data['show_position']['lat']=Genivi.data['lat'];
                Genivi.data['show_position']['lon']=Genivi.data['lon'];
                Genivi.data["mapback"]="NavigationRoute";
                disconnectSignals();
                pageOpen("NavigationBrowseMap");
            }
        }

        StdButton { source:StyleSheet.set_as_position[StyleSheet.SOURCE]; x:StyleSheet.set_as_position[StyleSheet.X]; y:StyleSheet.set_as_position[StyleSheet.Y]; width:StyleSheet.set_as_position[StyleSheet.WIDTH]; height:StyleSheet.set_as_position[StyleSheet.HEIGHT];
            id:position; disabled:false; next:calculate; prev:destination; explode:false;
            onClicked: {
                Genivi.data['position']=new Array;
                Genivi.data['position']['lat']=Genivi.data['lat'];
                Genivi.data['position']['lon']=Genivi.data['lon'];
                Genivi.data['position']['description']=Genivi.data['description'];
                setLocation();
                if (Genivi.data['destination'])
                    calculate.disabled=false;
            }
        }

        StdButton { source:StyleSheet.set_as_destination[StyleSheet.SOURCE]; x:StyleSheet.set_as_destination[StyleSheet.X]; y:StyleSheet.set_as_destination[StyleSheet.Y]; width:StyleSheet.set_as_destination[StyleSheet.WIDTH]; height:StyleSheet.set_as_destination[StyleSheet.HEIGHT];
            id:destination; disabled:false; next:position; prev:show; explode:false;
             onClicked: {
                Genivi.data['destination']=new Array;
                Genivi.data['destination']['lat']=Genivi.data['lat'];
                Genivi.data['destination']['lon']=Genivi.data['lon'];
                Genivi.data['destination']['description']=Genivi.data['description'];
                setLocation();
                if (Genivi.data['position'])
                    calculate.disabled=false;
                updateCurrentPosition();
            }
        }

        StdButton { source:StyleSheet.route[StyleSheet.SOURCE]; x:StyleSheet.route[StyleSheet.X]; y:StyleSheet.route[StyleSheet.Y]; width:StyleSheet.route[StyleSheet.WIDTH]; height:StyleSheet.route[StyleSheet.HEIGHT];textColor:StyleSheet.routeText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.routeText[StyleSheet.PIXELSIZE];
            id:calculate; text: Genivi.gettext("Route"); explode:false;
            onClicked: {
                var dest=latlon_to_map(Genivi.data['destination']);
                var pos=latlon_to_map(Genivi.data['position']);
                Genivi.routing_message(dbusIf,"SetWaypoints",["boolean",false,"array",["map",pos,"map",dest]]);
                Genivi.data['calculate_route']=true;
                disconnectSignals();
                Genivi.data['lat']='';
                Genivi.data['lon']='';
                pageOpen("NavigationCalculatedRoute");
            }
            disabled:!(Genivi.data['position'] && Genivi.data['destination']); next:calculate_curr; prev:position
        }

        StdButton { source:StyleSheet.calculate_curr[StyleSheet.SOURCE]; x:StyleSheet.calculate_curr[StyleSheet.X]; y:StyleSheet.calculate_curr[StyleSheet.Y]; width:StyleSheet.calculate_curr[StyleSheet.WIDTH]; height:StyleSheet.calculate_curr[StyleSheet.HEIGHT];textColor:StyleSheet.calculate_currText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.calculate_currText[StyleSheet.PIXELSIZE];
            id:calculate_curr; text: Genivi.gettext("GoTo"); explode:false;
            onClicked: {
                var dest=latlon_to_map(Genivi.data['destination']);
                Genivi.routing_message(dbusIf,"SetWaypoints",["boolean",true,"array",["map",dest]]);
                Genivi.data['calculate_route']=true;
                disconnectSignals();
                Genivi.data['lat']='';
                Genivi.data['lon']='';
                pageOpen("NavigationCalculatedRoute");
            }
            disabled:true; next:back; prev:calculate
        }

        StdButton { source:StyleSheet.back[StyleSheet.SOURCE]; x:StyleSheet.back[StyleSheet.X]; y:StyleSheet.back[StyleSheet.Y]; width:StyleSheet.back[StyleSheet.WIDTH]; height:StyleSheet.back[StyleSheet.HEIGHT];textColor:StyleSheet.backText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.backText[StyleSheet.PIXELSIZE];
            id:back; text: Genivi.gettext("Back");
            onClicked: {
                disconnectSignals();
                Genivi.data['lat']='';
                Genivi.data['lon']='';
                pageOpen("NavigationSearch");
            }
            disabled:false; next:show; prev:calculate_curr;
        }

        Component.onCompleted: {
            setLocation();
            updateCurrentPosition();
            connectSignals();
        }
    }
}
