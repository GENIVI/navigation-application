/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationCalculatedRoute.qml
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
import "Core/style-sheets/navigation-calculated-route-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    property string pagefile:"NavigationCalculatedRoute"
    next: back
    prev: show_route_in_list
	property Item routeCalculationSuccessfulSignal;
	property Item routeCalculationFailedSignal;
	property Item routeCalculationProgressUpdateSignal;
	property string routeText:" "

	DBusIf {
		id:dbusIf
	}

	function routeCalculationFailed(args)
	{
		//console.log("routeCalculationFailed:");
		//Genivi.dump("",args);

        statusValue.text=Genivi.gettext("CalculatedRouteFailed");
        Genivi.route_calculated = false;
        // Tell the FSA that there's no route available
        Genivi.fuelstopadvisor_ReleaseRouteHandle(dbusIf,Genivi.g_routing_handle);
	}

	function routeCalculationProgressUpdate(args)
	{
        statusValue.text=Genivi.gettext("CalculatedRouteInProgress");
        Genivi.route_calculated = false;
    }

	function updateStartStop()
	{
        var res=Genivi.guidance_GetGuidanceStatus(dbusIf);
        if (res[1] != Genivi.NAVIGATIONCORE_INACTIVE) {
            guidance_start.disabled=true;
            guidance_stop.disabled=false;
		} else {
            guidance_start.disabled=false;
            guidance_stop.disabled=true;
        }
	}

	function routeCalculationSuccessful(args)
    { //routeHandle 1, unfullfilledPreferences 3
        show_route_on_map.disabled=false;
        show_route_in_list.disabled=false;
        statusValue.text=Genivi.gettext("CalculatedRouteSuccess");
        Genivi.route_calculated = true;
        var res=Genivi.routing_GetRouteOverviewTimeAndDistance(dbusIf);

        var i, time = 0, distance = 0;
        for (i=0;i<res[1].length;i+=4)
        {
            if (res[1][i+1] == Genivi.NAVIGATIONCORE_TOTAL_TIME)
            {
                time = res[1][i+3][3][1];
            }
            else
            {
                if (Genivi.NAVIGATIONCORE_TOTAL_DISTANCE)
                {
                    distance = res[1][i+3][3][1];
                }
            }
        }

        distanceValue.text =Genivi.distance(distance);
        timeValue.text= Genivi.time(time);

        // Give the route handle to the FSA
        Genivi.fuelstopadvisor_SetRouteHandle(dbusIf,Genivi.g_routing_handle);
		updateStartStop();
	}

	function connectSignals()
    {
        routeCalculationSuccessfulSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.Routing","RouteCalculationSuccessful",menu,"routeCalculationSuccessful");
        routeCalculationFailedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.Routing","RouteCalculationFailed",menu,"routeCalculationFailed");
        routeCalculationProgressUpdateSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.Routing","RouteCalculationProgressUpdate",menu,"routeCalculationProgressUpdate");
    }

    function disconnectSignals()
    {
        routeCalculationSuccessfulSignal.destroy();
        routeCalculationFailedSignal.destroy();
        routeCalculationProgressUpdateSignal.destroy();
    }


    HMIBgImage {
        image:StyleSheet.navigation_calculated_route_menu_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

        Text {
            x:StyleSheet.guidanceTitle[Constants.X]; y:StyleSheet.guidanceTitle[Constants.Y]; width:StyleSheet.guidanceTitle[Constants.WIDTH]; height:StyleSheet.guidanceTitle[Constants.HEIGHT];color:StyleSheet.guidanceTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.guidanceTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.guidanceTitle[Constants.PIXELSIZE];
            id:guidanceTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Guidance")
        }

        Text {
            x:StyleSheet.displayRouteTitle[Constants.X]; y:StyleSheet.displayRouteTitle[Constants.Y]; width:StyleSheet.displayRouteTitle[Constants.WIDTH]; height:StyleSheet.displayRouteTitle[Constants.HEIGHT];color:StyleSheet.displayRouteTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.displayRouteTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.displayRouteTitle[Constants.PIXELSIZE];
            id:displayRouteTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("DisplayRoute")
        }


        Text {
            x:StyleSheet.distanceTitle[Constants.X]; y:StyleSheet.distanceTitle[Constants.Y]; width:StyleSheet.distanceTitle[Constants.WIDTH]; height:StyleSheet.distanceTitle[Constants.HEIGHT];color:StyleSheet.distanceTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.distanceTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.distanceTitle[Constants.PIXELSIZE];
            id:distanceTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("RouteDistance")
        }

        SmartText {
            x:StyleSheet.distanceValue[Constants.X]; y:StyleSheet.distanceValue[Constants.Y]; width:StyleSheet.distanceValue[Constants.WIDTH]; height:StyleSheet.distanceValue[Constants.HEIGHT];color:StyleSheet.distanceValue[Constants.TEXTCOLOR];styleColor:StyleSheet.distanceValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.distanceValue[Constants.PIXELSIZE];
            id:distanceValue
            text: ""
        }

        Text {
            x:StyleSheet.timeTitle[Constants.X]; y:StyleSheet.timeTitle[Constants.Y]; width:StyleSheet.timeTitle[Constants.WIDTH]; height:StyleSheet.timeTitle[Constants.HEIGHT];color:StyleSheet.timeTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.timeTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.timeTitle[Constants.PIXELSIZE];
            id:timeTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("RouteTime")
        }

        SmartText {
            x:StyleSheet.timeValue[Constants.X]; y:StyleSheet.timeValue[Constants.Y]; width:StyleSheet.timeValue[Constants.WIDTH]; height:StyleSheet.timeValue[Constants.HEIGHT];color:StyleSheet.timeValue[Constants.TEXTCOLOR];styleColor:StyleSheet.timeValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.timeValue[Constants.PIXELSIZE];
            id:timeValue
            text: ""
        }

        Text {
            x:StyleSheet.statusTitle[Constants.X]; y:StyleSheet.statusTitle[Constants.Y]; width:StyleSheet.statusTitle[Constants.WIDTH]; height:StyleSheet.statusTitle[Constants.HEIGHT];color:StyleSheet.statusTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.statusTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.statusTitle[Constants.PIXELSIZE];
            id:statusTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("StatusTitle")
        }

        SmartText {
            x:StyleSheet.statusValue[Constants.X]; y:StyleSheet.statusValue[Constants.Y]; width:StyleSheet.statusValue[Constants.WIDTH]; height:StyleSheet.statusValue[Constants.HEIGHT];color:StyleSheet.statusValue[Constants.TEXTCOLOR];styleColor:StyleSheet.statusValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.statusValue[Constants.PIXELSIZE];
            id:statusValue
            text: ""
        }

        StdButton {
            source:StyleSheet.show_route_on_map[Constants.SOURCE]; x:StyleSheet.show_route_on_map[Constants.X]; y:StyleSheet.show_route_on_map[Constants.Y]; width:StyleSheet.show_route_on_map[Constants.WIDTH]; height:StyleSheet.show_route_on_map[Constants.HEIGHT];
            id: show_route_on_map
            explode:false; disabled:true; next:show_route_in_list; prev:back
            onClicked: {
                disconnectSignals();
                Genivi.data["mapback"]="NavigationCalculatedRoute";
                Genivi.data["show_route_handle"]=Genivi.routing_handle(dbusIf);
                Genivi.data["zoom_route_handle"]=Genivi.routing_handle(dbusIf);
                mapMenu();
            }
        }
        StdButton {
            source:StyleSheet.show_route_in_list[Constants.SOURCE]; x:StyleSheet.show_route_in_list[Constants.X]; y:StyleSheet.show_route_in_list[Constants.Y]; width:StyleSheet.show_route_in_list[Constants.WIDTH]; height:StyleSheet.show_route_in_list[Constants.HEIGHT];
            id:show_route_in_list;
            explode:false; disabled:true; next:back; prev:show_route_on_map;
            onClicked: {
                entryMenu("NavigationRouteDescription",menu);
            }
        }

        StdButton {
            source:StyleSheet.guidance_start[Constants.SOURCE]; x:StyleSheet.guidance_start[Constants.X]; y:StyleSheet.guidance_start[Constants.Y]; width:StyleSheet.guidance_start[Constants.WIDTH]; height:StyleSheet.guidance_start[Constants.HEIGHT];textColor:StyleSheet.startText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.startText[Constants.PIXELSIZE];
            id:guidance_start; text: Genivi.gettext("On");explode:false; disabled:true; next:guidance_stop; prev:show_route_on_map
            onClicked: {
                disconnectSignals();
                Genivi.guidance_StartGuidance(dbusIf,Genivi.routing_handle(dbusIf));
                Genivi.data["mapback"]="NavigationCalculatedRoute";
                Genivi.data["show_route_handle"]=Genivi.routing_handle(dbusIf);
                Genivi.data["show_current_position"]=true;
                mapMenu();
            }
        }
        StdButton {
            source:StyleSheet.guidance_stop[Constants.SOURCE]; x:StyleSheet.guidance_stop[Constants.X]; y:StyleSheet.guidance_stop[Constants.Y]; width:StyleSheet.guidance_stop[Constants.WIDTH]; height:StyleSheet.guidance_stop[Constants.HEIGHT];textColor:StyleSheet.stopText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.stopText[Constants.PIXELSIZE];
            id:guidance_stop;text: Genivi.gettext("Off");explode:false; disabled:true; next:show_route_on_map; prev:guidance_start
            onClicked: {
                Genivi.guidance_StopGuidance(dbusIf);
                guidance_start.disabled=false;
                guidance_stop.disabled=true;
            }
        }
        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); disabled:false; next:show_route_on_map; prev:show_route_in_list;
            onClicked: {
                disconnectSignals();
                leaveMenu();
            }
        }
    }

	Component.onCompleted: {
		//console.log(Genivi.data);
		connectSignals();
		if (Genivi.data["calculate_route"]) {
            Genivi.routing_CalculateRoute(dbusIf);
			delete(Genivi.data["calculate_route"]);
		} else {
			routeCalculationSuccessful("dummy");
		}
		updateStartStop();
	}
}
