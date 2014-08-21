/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file CameraSettings.qml
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
import "Core/style-sheets/navigation-browse-map-settings-css.js" as StyleSheetSettings;
import lbs.plugin.dbusif 1.0

HMIMenu {
    id: menu

    DBusIf {
        id:dbusIf
    }

    Timer {
        id:move_timer
        repeat:true
        triggeredOnStart:false
        property real lat;
        property real lon;
        property bool active;
        onTriggered: {
            if (active) {
                var res=Genivi.mapviewercontrol_message(dbusIf, "GetTargetPoint", []);
                if (res[0] == 'structure') {
                    res[1][1]+=lat;
                    res[1][3]+=lon;
                    Genivi.mapviewercontrol_message(dbusIf, "SetTargetPoint", res);
                }
                interval=50;
                restart();
            }
        }
    }

    Timer {
        id:camera_timer
        repeat:true
        triggeredOnStart:false
        property bool active;
        property string camera_value;
        property real step;
        property bool clamp;
        property real clamp_value;
        onTriggered: {
            if (active) {
                var res=Genivi.mapviewercontrol_message(dbusIf, "Get"+camera_value, []);
                if (res[0] == 'double' || res[0] == 'int32' || res[0] == 'uint32') {
                    res[1]+=step;
                    if (clamp) {
                        if (step > 0 && res[1] > clamp_value) {
                            res[1]=clamp_value;
                        }
                        if (step < 0 && res[1] < clamp_value) {
                            res[1]=clamp_value;
                        }
                    }
                    Genivi.mapviewercontrol_message(dbusIf, "Set"+camera_value, res);
                }
                interval=50;
                restart();
            }
        }
    }

    function showSurfaces()
    {
        Genivi.lm_message(dbusIf,"ServiceConnect",["uint32",dbusIf.pid()]);
        Genivi.lm_message(dbusIf,"SetSurfaceDestinationRegion",["uint32",2000+Genivi.g_map_handle[1],"uint32",map.x,"uint32",map.y,"uint32",map.width,"uint32",map.height]);
        Genivi.lm_message(dbusIf,"SetSurfaceSourceRegion",["uint32",2000+Genivi.g_map_handle[1],"uint32",0,"uint32",0,"uint32",map.width,"uint32",map.height]);
        Genivi.lm_message(dbusIf,"SetSurfaceVisibility",["uint32",2000+Genivi.g_map_handle[1],"boolean",true]);
        Genivi.lm_message(dbusIf,"CommitChanges",[]);
        Genivi.lm_message(dbusIf,"ServiceDisconnect",["uint32",dbusIf.pid()]);
    }

    function hideSurfaces()
    {
        Genivi.lm_message(dbusIf,"ServiceConnect",["uint32",dbusIf.pid()]);
        Genivi.lm_message(dbusIf,"SetSurfaceVisibility",["uint32",2000+Genivi.g_map_handle[1],"boolean",false]);
        Genivi.lm_message(dbusIf,"CommitChanges",[]);
        Genivi.lm_message(dbusIf,"ServiceDisconnect",["uint32",dbusIf.pid()]);
    }

    function move_start(lat, lon)
    {
        Genivi.mapviewercontrol_message(dbusIf, "SetFollowCarMode", ["boolean",false]);
        move_timer.lat=lat/10000;
        move_timer.lon=lon/10000;
        move_timer.active=true;
        move_timer.triggered();
    }

    function move_stop()
    {
        move_timer.active=false;
        move_timer.stop();
    }

    function camera_start(camera_value, step)
    {
        camera_timer.camera_value=camera_value;
        camera_timer.step=step;
        camera_timer.active=true;
        camera_timer.triggered();
    }

    function camera_start_clamp(camera_value, step, clampvalue)
    {
        camera_timer.clamp=true;
        camera_timer.clamp_value=clampvalue;
        camera_start(camera_value, step);
    }

    function camera_stop()
    {
        camera_timer.active=false;
        camera_timer.stop();
        camera_timer.clamp=false;
    }

    function set_angle(angle)
    {
        Genivi.mapviewercontrol_message(dbusIf, "SetMapViewRotation", ["int32",angle,"int32",15]);
    }

    function updateMapViewer()
    {
        var res=Genivi.mapviewercontrol_message(dbusIf,"GetMapViewPerspective",[]);
        if (res[0] == "uint16") {
            if (res[1] == Genivi.MAPVIEWER_2D) {
                perspective.text=Genivi.gettext("CameraPerspective3d");
            } else {
                perspective.text=Genivi.gettext("CameraPerspective2d");
            }
        } else {
            console.log("Unexpected result from GetMapViewPerspective:");
            Genivi.dump("",res);
        }
        var res=Genivi.mapviewercontrol_message(dbusIf,"GetDisplayedRoutes",[]);
        if (res[0] == "array" && res[1] && res[1].length) {
            split.disabled=false;
        } else {
            split.disabled=true;
        }
        if (Genivi.g_map_handle2) {
            split.text=Genivi.gettext("Join");
        } else {
            split.text=Genivi.gettext("Split");
        }
    }

    function toggleDayNight()
    {
        var res=Genivi.mapviewercontrol_message(dbusIf, "GetMapViewTheme", []);
        if (res[0] == "uint16" && res[1] == Genivi.MAPVIEWER_THEME_1) {
            Genivi.mapviewercontrol_message(dbusIf,"SetMapViewTheme",["uint16",Genivi.MAPVIEWER_THEME_2]);
            if (Genivi.g_map_handle2) {
                Genivi.mapviewercontrol_message2(dbusIf,"SetMapViewTheme",["uint16",Genivi.MAPVIEWER_THEME_2]);
            }
            daynight.text=Genivi.gettext("Day");
        } else {
            Genivi.mapviewercontrol_message(dbusIf,"SetMapViewTheme",["uint16",Genivi.MAPVIEWER_THEME_1]);
            if (Genivi.g_map_handle2) {
                Genivi.mapviewercontrol_message2(dbusIf,"SetMapViewTheme",["uint16",Genivi.MAPVIEWER_THEME_1]);
            }
            daynight.text=Genivi.gettext("Night");
        }
    }

    function updateDayNight()
    {
        var res=Genivi.mapviewercontrol_message(dbusIf, "GetMapViewTheme", []);
        if (res[0] == "uint16" && res[1] == Genivi.MAPVIEWER_THEME_1) {
            daynight.text=Genivi.gettext("Night");
        } else {
            daynight.text=Genivi.gettext("Day");
        }
    }

    function togglePerspective()
    {
        if (perspective.text == Genivi.gettext("CameraPerspective2d")) {
            Genivi.mapviewercontrol_message(dbusIf,"SetMapViewPerspective",["uint16",Genivi.MAPVIEWER_2D]);
        } else {
            Genivi.mapviewercontrol_message(dbusIf,"SetMapViewPerspective",["uint16",Genivi.MAPVIEWER_3D]);
        }
        updateMapViewer();
    }

    function toggleSplit()
    {
        hideSurfaces();
        var res=Genivi.mapviewercontrol_message(dbusIf,"GetDisplayedRoutes",[]);
        var res3=Genivi.mapviewercontrol_message(dbusIf, "GetMapViewTheme", []);
        if (split.text == Genivi.gettext("Split")) {
            Genivi.map_handle_clear(dbusIf);
            Genivi.map_handle2(dbusIf,map.width/2,map.height,Genivi.MAPVIEWER_MAIN_MAP);
            Genivi.map_handle(dbusIf,map.width/2,map.height,Genivi.MAPVIEWER_MAIN_MAP);
            if (res[0] == "array" && res[1] && res[1].length) {
                var res2=Genivi.routing_message_get(dbusIf, "GetRouteBoundingBox", []);
                if (res2[0] == "structure") {
                    Genivi.mapviewercontrol_message2(dbusIf, "SetMapViewBoundingBox", res2);
                } else {
                    console.log("Unexpected result from GetRouteBoundingBox:");
                    Genivi.dump("",res2);
                }
            }
            if (res3[0] == "uint16") {
                Genivi.mapviewercontrol_message(dbusIf, "SetMapViewTheme", res3);
                Genivi.mapviewercontrol_message2(dbusIf, "SetMapViewTheme", res3);
            }
            Genivi.mapviewercontrol_message(dbusIf, "SetFollowCarMode", ["boolean",true]);
        } else {
            Genivi.map_handle_clear2(dbusIf);
            Genivi.map_handle_clear(dbusIf);
            Genivi.map_handle(dbusIf,map.width,map.height,Genivi.MAPVIEWER_MAIN_MAP);
            if (res3[0] == "uint16") {
                Genivi.mapviewercontrol_message(dbusIf, "SetMapViewTheme", res3);
            }
            Genivi.mapviewercontrol_message(dbusIf, "SetFollowCarMode", ["boolean",true]);
        }
        if (res[0] == "array" && res[1] && res[1].length) {
            for (var i = 0 ; i < res[1].length ; i+=2) {
                Genivi.mapviewercontrol_message(dbusIf, "DisplayRoute", res[1][i+1]);
                if (split.text == Genivi.gettext("Split")) {
                    Genivi.mapviewercontrol_message2(dbusIf, "DisplayRoute", res[1][i+1]);
                }
            }
        }
        showSurfaces();
        updateMapViewer();
    }

    function disableSplit()
    {
        if (Genivi.g_map_handle2) {
            toggleSplit();
        }
    }

    Rectangle {
        id:map
        x:0
        y:0
        height:menu.height
        width:menu.width
        color:"#ffff7e"
        Rectangle {
            opacity: 0.8
            width: StyleSheetSettings.navigation_browse_map_settings_background[Constants.WIDTH]
            height: StyleSheetSettings.navigation_browse_map_settings_background[Constants.HEIGHT]
            x: Constants.MENU_CAMERA_SETTINGS_X
            y: Constants.MENU_CAMERA_SETTINGS_Y
            HMIBgImage {
                id: content
                image:StyleSheetSettings.navigation_browse_map_settings_background[Constants.SOURCE];
                anchors { fill: parent; topMargin: parent.headlineHeight}


                 Text {
                     x:StyleSheetSettings.tiltText[StyleSheetSettings.X]; y:StyleSheetSettings.tiltText[StyleSheetSettings.Y]; width:StyleSheetSettings.tiltText[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.tiltText[StyleSheetSettings.HEIGHT];color:StyleSheetSettings.tiltText[StyleSheetSettings.TEXTCOLOR];styleColor:StyleSheetSettings.tiltText[StyleSheetSettings.STYLECOLOR]; font.pixelSize:StyleSheetSettings.tiltText[StyleSheetSettings.PIXELSIZE];
                     id:tiltText;
                     style: Text.Sunken;
                     smooth: true
                     text: Genivi.gettext("CameraTilt")
                      }

                 StdButton {source:StyleSheetSettings.tiltp[Constants.SOURCE]; x:StyleSheetSettings.tiltp[StyleSheetSettings.X]; y:StyleSheetSettings.tiltp[StyleSheetSettings.Y]; width:StyleSheetSettings.tiltp[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.tiltp[StyleSheetSettings.HEIGHT];
                            id:tiltp; explode:false; next:tiltm; prev:exit;
                         onPressed: {camera_start_clamp("CameraTiltAngle",-10,0);}
                         onReleased: {camera_stop();}
                 }

                 StdButton {source:StyleSheetSettings.tiltm[Constants.SOURCE]; x:StyleSheetSettings.tiltm[StyleSheetSettings.X]; y:StyleSheetSettings.tiltm[StyleSheetSettings.Y]; width:StyleSheetSettings.tiltm[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.tiltm[StyleSheetSettings.HEIGHT];
                            id:tiltm; explode:false; next:heightp; prev:tiltp;
                         onPressed: {camera_start_clamp("CameraTiltAngle",10,90);}
                         onReleased: {camera_stop();}
                 }

                 Text {
                     x:StyleSheetSettings.heightText[StyleSheetSettings.X]; y:StyleSheetSettings.heightText[StyleSheetSettings.Y]; width:StyleSheetSettings.heightText[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.heightText[StyleSheetSettings.HEIGHT];color:StyleSheetSettings.heightText[StyleSheetSettings.TEXTCOLOR];styleColor:StyleSheetSettings.heightText[StyleSheetSettings.STYLECOLOR]; font.pixelSize:StyleSheetSettings.heightText[StyleSheetSettings.PIXELSIZE];
                     id:heightText;
                     style: Text.Sunken;
                     smooth: true
                     text: Genivi.gettext("CameraHeight")
                      }

                 StdButton {source:StyleSheetSettings.heightp[Constants.SOURCE]; x:StyleSheetSettings.heightp[StyleSheetSettings.X]; y:StyleSheetSettings.heightp[StyleSheetSettings.Y]; width:StyleSheetSettings.heightp[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.heightp[StyleSheetSettings.HEIGHT];
                            id:heightp;explode:false; next:heightm; prev:tiltm;
                         onPressed: {camera_start("CameraHeight",10);}
                         onReleased: {camera_stop();}
                 }

                 StdButton {source:StyleSheetSettings.heightm[Constants.SOURCE]; x:StyleSheetSettings.heightm[StyleSheetSettings.X]; y:StyleSheetSettings.heightm[StyleSheetSettings.Y]; width:StyleSheetSettings.heightm[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.heightm[StyleSheetSettings.HEIGHT];
                            id:heightm; explode:false; next:distancep; prev:heightp;
                         onPressed: {camera_start("CameraHeight",-10);}
                         onReleased: {camera_stop();}
                 }

                 Text {
                     x:StyleSheetSettings.distanceText[StyleSheetSettings.X]; y:StyleSheetSettings.distanceText[StyleSheetSettings.Y]; width:StyleSheetSettings.distanceText[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.distanceText[StyleSheetSettings.HEIGHT];color:StyleSheetSettings.distanceText[StyleSheetSettings.TEXTCOLOR];styleColor:StyleSheetSettings.distanceText[StyleSheetSettings.STYLECOLOR]; font.pixelSize:StyleSheetSettings.distanceText[StyleSheetSettings.PIXELSIZE];
                     id:distanceText;
                     style: Text.Sunken;
                     smooth: true
                     text: Genivi.gettext("CameraDistance")
                      }

                 StdButton {source:StyleSheetSettings.distancep[Constants.SOURCE]; x:StyleSheetSettings.distancep[StyleSheetSettings.X]; y:StyleSheetSettings.distancep[StyleSheetSettings.Y]; width:StyleSheetSettings.distancep[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.distancep[StyleSheetSettings.HEIGHT];
                            id:distancep; explode:false; next:distancem; prev:heightm;
                         onPressed: {camera_start("CameraDistanceFromTargetPoint",10);}
                         onReleased: {camera_stop();}
                 }

                 StdButton {source:StyleSheetSettings.distancem[Constants.SOURCE]; x:StyleSheetSettings.distancem[StyleSheetSettings.X]; y:StyleSheetSettings.distancem[StyleSheetSettings.Y]; width:StyleSheetSettings.distancem[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.distancem[StyleSheetSettings.HEIGHT];
                            id:distancem; explode:false; next:north; prev:distancep;
                         onPressed: {camera_start("CameraDistanceFromTargetPoint",-10);}
                         onReleased: {camera_stop();}
                 }

                 StdButton {source:StyleSheetSettings.north[Constants.SOURCE]; x:StyleSheetSettings.north[StyleSheetSettings.X]; y:StyleSheetSettings.north[StyleSheetSettings.Y]; width:StyleSheetSettings.north[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.north[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.northText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.northText[StyleSheetSettings.PIXELSIZE];
                            id:north; text: Genivi.gettext("North"); explode:false; next:south; prev:distancem;
                     onClicked: {
                         set_angle(0);
                     }
                 }

                 StdButton { source:StyleSheetSettings.south[Constants.SOURCE]; x:StyleSheetSettings.south[StyleSheetSettings.X]; y:StyleSheetSettings.south[StyleSheetSettings.Y]; width:StyleSheetSettings.south[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.south[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.southText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.southText[StyleSheetSettings.PIXELSIZE];
                            id:south; text:Genivi.gettext("South"); explode:false; next:east; prev:north;
                     onClicked: {
                         set_angle(180);
                     }
                 }

                 StdButton {source:StyleSheetSettings.east[Constants.SOURCE]; x:StyleSheetSettings.east[StyleSheetSettings.X]; y:StyleSheetSettings.east[StyleSheetSettings.Y]; width:StyleSheetSettings.east[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.east[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.eastText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.eastText[StyleSheetSettings.PIXELSIZE];
                            id:east; text:Genivi.gettext("East"); explode:false; next:west; prev:south;
                     onClicked: {
                         set_angle(90);
                     }
                 }

                 StdButton {source:StyleSheetSettings.west[Constants.SOURCE]; x:StyleSheetSettings.west[StyleSheetSettings.X]; y:StyleSheetSettings.west[StyleSheetSettings.Y]; width:StyleSheetSettings.west[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.west[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.westText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.westText[StyleSheetSettings.PIXELSIZE];
                            id:west; text:Genivi.gettext("West"); explode:false; next:exit; prev:east;
                     onClicked: {
                         set_angle(270);
                     }
                 }

                 StdButton {source:StyleSheetSettings.exit[Constants.SOURCE]; x:StyleSheetSettings.exit[StyleSheetSettings.X]; y:StyleSheetSettings.exit[StyleSheetSettings.Y]; width:StyleSheetSettings.exit[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.exit[StyleSheetSettings.HEIGHT];
                            id:exit; explode:false; next:tiltp; prev:west;
                     onClicked: {
                         Genivi.data['show_current_position']=true;
                         move_stop();
                         camera_stop();
                         hideSurfaces();
                         pageOpen("NavigationBrowseMap");
                     }
                 }
                 StdButton {source:StyleSheetSettings.perspective[Constants.SOURCE]; x:StyleSheetSettings.perspective[StyleSheetSettings.X]; y:StyleSheetSettings.perspective[StyleSheetSettings.Y]; width:StyleSheetSettings.perspective[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.perspective[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.perspectiveText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.perspectiveText[StyleSheetSettings.PIXELSIZE];
                            id:perspective; text:Genivi.gettext("CameraPerspective3d"); explode:false; next:split; prev:zoom_out;
                         onClicked: {togglePerspective();}
                 }

                 StdButton {source:StyleSheetSettings.split[Constants.SOURCE]; x:StyleSheetSettings.split[StyleSheetSettings.X]; y:StyleSheetSettings.split[StyleSheetSettings.Y]; width:StyleSheetSettings.split[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.split[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.splitText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.splitText[StyleSheetSettings.PIXELSIZE];
                            id:split; text:Genivi.gettext("Split"); explode:false; next:orientation; prev:perspective;
                         onClicked: {toggleSplit();}
                 }

                 StdButton {source:StyleSheetSettings.daynight[Constants.SOURCE]; x:StyleSheetSettings.daynight[StyleSheetSettings.X]; y:StyleSheetSettings.daynight[StyleSheetSettings.Y]; width:StyleSheetSettings.daynight[StyleSheetSettings.WIDTH]; height:StyleSheetSettings.daynight[StyleSheetSettings.HEIGHT];textColor:StyleSheetSettings.daynightText[StyleSheetSettings.TEXTCOLOR]; pixelSize:StyleSheetSettings.daynightText[StyleSheetSettings.PIXELSIZE];
                            id:daynight; text:Genivi.gettext("Day"); explode:false; next:up; prev:stop;
                     onClicked: {
                         toggleDayNight();
                     }
                 }

             }
        }
     }
    Component.onCompleted: {
        Genivi.map_handle(dbusIf,menu.width,menu.height,Genivi.MAPVIEWER_MAIN_MAP);
        showSurfaces();
        updateMapViewer();
        updateDayNight();
    }
}
