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
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    headlineFg: "grey"
    headlineBg: "blue"
    text: Genivi.gettext("CameraSettings")
	next: north
	prev: distancem

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


	Row {
		id:content
		y:30;
		x:menu.wspc/2;
		height:content.h
		property real w: menu.w(5);
		property real h: menu.h(4);
		property real scrollspeed: 40
		spacing: menu.wspc/3;

        StdButton { id:north; text:"North"; explode:false; next:south; prev:distancem; pixelSize:Constants.MENU_BROWSE_MAP_TEXT_PIXEL_SIZE;
			onClicked: {
				set_angle(0);
			}
		}

        StdButton { id:south; text:"South"; explode:false; next:east; prev:north; pixelSize:Constants.MENU_BROWSE_MAP_TEXT_PIXEL_SIZE;
			onClicked: {
				set_angle(180);
			}
		}

        StdButton { id:east; text:"East"; explode:false; next:west; prev:south; pixelSize:Constants.MENU_BROWSE_MAP_TEXT_PIXEL_SIZE;
			onClicked: {
				set_angle(90);
			}
		}

        StdButton { id:west; text:"West"; explode:false; next:back; prev:east; pixelSize:Constants.MENU_BROWSE_MAP_TEXT_PIXEL_SIZE;
			onClicked: {
				set_angle(270);
			}
		}
        StdButton { id:back; text:"Back"; explode:false; next:tiltp; prev:west; pixelSize:Constants.MENU_BROWSE_MAP_TEXT_PIXEL_SIZE;
			onClicked: {
				Genivi.data['show_current_position']=true;
				move_stop();
				camera_stop();
                                hideSurfaces();
                                pageOpen("NavigationBrowseMap");
			}
		}
	}
	Rectangle {
		id:map
		y:content.y+content.height+4
		height:menu.height-y-bottom.height-8
		width:menu.width
		color:"#ffff7e"
	}
	Row {
		id:bottom
		y:menu.height-height-4
		x:menu.wspc/2;
		height:content.h
		spacing:menu.wspc/3

        StdButton { id:tiltp; text:"Tilt+"; explode:false; next:tiltm; prev:back; pixelSize:Constants.MENU_BROWSE_MAP_TEXT_PIXEL_SIZE;
			    onPressed: {camera_start_clamp("CameraTiltAngle",-10,0);}
			    onReleased: {camera_stop();}
		}

        StdButton { id:tiltm; text:"Tilt-"; explode:false; next:heightp; prev:tiltp; pixelSize:Constants.MENU_BROWSE_MAP_TEXT_PIXEL_SIZE;
			    onPressed: {camera_start_clamp("CameraTiltAngle",10,90);}
			    onReleased: {camera_stop();}
		}

        StdButton { id:heightp; text:"Height+"; explode:false; next:heightm; prev:tiltm; pixelSize:Constants.MENU_BROWSE_MAP_TEXT_PIXEL_SIZE;
			    onPressed: {camera_start("CameraHeight",10);}
			    onReleased: {camera_stop();}
		}

        StdButton { id:heightm; text:"Height-"; explode:false; next:distancep; prev:heightp; pixelSize:Constants.MENU_BROWSE_MAP_TEXT_PIXEL_SIZE;
			    onPressed: {camera_start("CameraHeight",-10);}
			    onReleased: {camera_stop();}
		}

        StdButton { id:distancep; text:"Distance+"; explode:false; next:distancem; prev:heightm; pixelSize:Constants.MENU_BROWSE_MAP_TEXT_PIXEL_SIZE;
			    onPressed: {camera_start("CameraDistanceFromTargetPoint",10);}
			    onReleased: {camera_stop();}
		}

        StdButton { id:distancem; text:"Distance-"; explode:false; next:north; prev:distancep; pixelSize:Constants.MENU_BROWSE_MAP_TEXT_PIXEL_SIZE;
			    onPressed: {camera_start("CameraDistanceFromTargetPoint",-10);}
			    onReleased: {camera_stop();}
		}

	}
	Component.onCompleted: {
		Genivi.map_handle(dbusIf,map.width,map.height,Genivi.MAPVIEWER_MAIN_MAP);
		showSurfaces();
	}
}
