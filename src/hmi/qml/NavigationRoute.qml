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
import QtQuick 2.1 
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/navigation-route-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

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
        image:StyleSheet.navigation_route_menu_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

        Text {
            x:StyleSheet.locationTitle[Constants.X]; y:StyleSheet.locationTitle[Constants.Y]; width:StyleSheet.locationTitle[Constants.WIDTH]; height:StyleSheet.locationTitle[Constants.HEIGHT];color:StyleSheet.locationTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.locationTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.locationTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            id:locationTitle
            text: Genivi.gettext("EnteredLocation")
        }

        Text {
            x:StyleSheet.locationValue[Constants.X]; y:StyleSheet.locationValue[Constants.Y]; width:StyleSheet.locationValue[Constants.WIDTH]; height:StyleSheet.locationValue[Constants.HEIGHT];color:StyleSheet.locationValue[Constants.TEXTCOLOR];styleColor:StyleSheet.locationValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.locationValue[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            wrapMode: Text.WordWrap
            id:locationValue
        }

        Text {
            x:StyleSheet.positionTitle[Constants.X]; y:StyleSheet.positionTitle[Constants.Y]; width:StyleSheet.positionTitle[Constants.WIDTH]; height:StyleSheet.positionTitle[Constants.HEIGHT];color:StyleSheet.positionTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.positionTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.positionTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            id:positionTitle
            text: Genivi.gettext("Position")
        }

        Text {
            x:StyleSheet.positionValue[Constants.X]; y:StyleSheet.positionValue[Constants.Y]; width:StyleSheet.positionValue[Constants.WIDTH]; height:StyleSheet.positionValue[Constants.HEIGHT];color:StyleSheet.positionValue[Constants.TEXTCOLOR];styleColor:StyleSheet.positionValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.positionValue[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            wrapMode: Text.WordWrap
            id:positionValue
        }

        Text {
            x:StyleSheet.destinationTitle[Constants.X]; y:StyleSheet.destinationTitle[Constants.Y]; width:StyleSheet.destinationTitle[Constants.WIDTH]; height:StyleSheet.destinationTitle[Constants.HEIGHT];color:StyleSheet.destinationTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.destinationTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.destinationTitle[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            id:destinationTitle
            text: Genivi.gettext("Destination")
        }

        Text {
            x:StyleSheet.destinationValue[Constants.X]; y:StyleSheet.destinationValue[Constants.Y]; width:StyleSheet.destinationValue[Constants.WIDTH]; height:StyleSheet.destinationValue[Constants.HEIGHT];color:StyleSheet.destinationValue[Constants.TEXTCOLOR];styleColor:StyleSheet.destinationValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.destinationValue[Constants.PIXELSIZE];
            style: Text.Sunken;
            smooth: true
            wrapMode: Text.WordWrap
            id:destinationValue
        }

        StdButton { source:StyleSheet.show_location_on_map[Constants.SOURCE]; x:StyleSheet.show_location_on_map[Constants.X]; y:StyleSheet.show_location_on_map[Constants.Y]; width:StyleSheet.show_location_on_map[Constants.WIDTH]; height:StyleSheet.show_location_on_map[Constants.HEIGHT];
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

        StdButton { source:StyleSheet.set_as_position[Constants.SOURCE]; x:StyleSheet.set_as_position[Constants.X]; y:StyleSheet.set_as_position[Constants.Y]; width:StyleSheet.set_as_position[Constants.WIDTH]; height:StyleSheet.set_as_position[Constants.HEIGHT];
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

        StdButton { source:StyleSheet.set_as_destination[Constants.SOURCE]; x:StyleSheet.set_as_destination[Constants.X]; y:StyleSheet.set_as_destination[Constants.Y]; width:StyleSheet.set_as_destination[Constants.WIDTH]; height:StyleSheet.set_as_destination[Constants.HEIGHT];
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

        StdButton { source:StyleSheet.route[Constants.SOURCE]; x:StyleSheet.route[Constants.X]; y:StyleSheet.route[Constants.Y]; width:StyleSheet.route[Constants.WIDTH]; height:StyleSheet.route[Constants.HEIGHT];textColor:StyleSheet.routeText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.routeText[Constants.PIXELSIZE];
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

        StdButton { source:StyleSheet.calculate_curr[Constants.SOURCE]; x:StyleSheet.calculate_curr[Constants.X]; y:StyleSheet.calculate_curr[Constants.Y]; width:StyleSheet.calculate_curr[Constants.WIDTH]; height:StyleSheet.calculate_curr[Constants.HEIGHT];textColor:StyleSheet.calculate_currText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.calculate_currText[Constants.PIXELSIZE];
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

        StdButton { source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back");
            onClicked: {
                disconnectSignals();
                Genivi.data['lat']='';
                Genivi.data['lon']='';
                pageOpen("NavigationSearch");
            }
            disabled:false; next:show; prev:calculate_curr;
        }

    }
    Component.onCompleted: {
        setLocation();
        updateCurrentPosition();
        connectSignals();
    }
}
