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
import "Core/style-sheets/navigation-calculated-route-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    headlineFg: "grey"
    headlineBg: "blue"
    text: Genivi.gettext("NavigationCalculatedRoute")
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

        menu.text=Genivi.gettext("CalculatedRouteFailed");
	}

	function routeCalculationProgressUpdate(args)
	{
        menu.text=Genivi.gettext("CalculatedRouteInProgress")+ " "+args[7]+"%";
	}

	function updateStartStop()
	{
		var res=Genivi.nav_message(dbusIf,"Guidance","GetGuidanceStatus",[]);
		//Genivi.dump("",res);
		if (res[0] == "uint16" && res[1] != Genivi.NAVIGATIONCORE_INACTIVE) {
            guidance_start.disabled=true;
            guidance_stop.disabled=false;
		} else {
            guidance_start.disabled=false;
            guidance_stop.disabled=true;
		}
	}

	function routeCalculationSuccessful(args)
	{
        show_route_on_map.disabled=false;
        show_route_in_list.disabled=false;
        menu.text=Genivi.gettext("NavigationCalculatedRoute");

        var para=[], pref=[];
        pref=pref.concat("uint16",Genivi.NAVIGATIONCORE_TOTAL_TIME,"uint16",Genivi.NAVIGATIONCORE_TOTAL_DISTANCE);
        para = para.concat("array",[pref]);
        var res=Genivi.routing_message_get(dbusIf,"GetRouteOverview",para);

        var i, time = 0, distance = 0;
        if (res[0] == "map") {
             for (i=0;i<res[1].length;i+=4)
            {
                if (res[1][i] == "uint16" && res[1][i+1] == Genivi.NAVIGATIONCORE_TOTAL_TIME)
                {
                    if (res[1][i+2] == "variant" && res[1][i+3][0] == "uint32")
                    {
                        time = res[1][i+3][1];
                    }
                }
                else
                {
                    if (res[1][i] == "uint16" && res[1][i+1] == Genivi.NAVIGATIONCORE_TOTAL_DISTANCE)
                    {
                        if (res[1][i+2] == "variant" && res[1][i+3][0] == "uint32")
                        {
                            distance = res[1][i+3][1];
                        }
                    }

                }
            }

            distanceValue.text =Genivi.distance(distance);
            timeValue.text= Genivi.time(time);

		} else {
			console.log("Unexpected result from GetRouteOverview:\n");
			Genivi.dump("",res);
		}
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
        image:StyleSheet.navigation_calculated_route_menu_background[StyleSheet.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

        Text {
            x:StyleSheet.guidanceTitle[StyleSheet.X]; y:StyleSheet.guidanceTitle[StyleSheet.Y]; width:StyleSheet.guidanceTitle[StyleSheet.WIDTH]; height:StyleSheet.guidanceTitle[StyleSheet.HEIGHT];color:StyleSheet.guidanceTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.guidanceTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.guidanceTitle[StyleSheet.PIXELSIZE];
            id:guidanceTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Guidance")
        }

        Text {
            x:StyleSheet.displayRouteTitle[StyleSheet.X]; y:StyleSheet.displayRouteTitle[StyleSheet.Y]; width:StyleSheet.displayRouteTitle[StyleSheet.WIDTH]; height:StyleSheet.displayRouteTitle[StyleSheet.HEIGHT];color:StyleSheet.displayRouteTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.displayRouteTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.displayRouteTitle[StyleSheet.PIXELSIZE];
            id:displayRouteTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("DisplayRoute")
        }


        Text {
            x:StyleSheet.distanceTitle[StyleSheet.X]; y:StyleSheet.distanceTitle[StyleSheet.Y]; width:StyleSheet.distanceTitle[StyleSheet.WIDTH]; height:StyleSheet.distanceTitle[StyleSheet.HEIGHT];color:StyleSheet.distanceTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.distanceTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.distanceTitle[StyleSheet.PIXELSIZE];
            id:distanceTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("RouteDistance")
        }

        Text {
            x:StyleSheet.distanceValue[StyleSheet.X]; y:StyleSheet.distanceValue[StyleSheet.Y]; width:StyleSheet.distanceValue[StyleSheet.WIDTH]; height:StyleSheet.distanceValue[StyleSheet.HEIGHT];color:StyleSheet.distanceValue[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.distanceValue[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.distanceValue[StyleSheet.PIXELSIZE];
            id:distanceValue
            wrapMode: Text.WordWrap
            style: Text.Sunken;
            smooth: true
        }

        Text {
            x:StyleSheet.timeTitle[StyleSheet.X]; y:StyleSheet.timeTitle[StyleSheet.Y]; width:StyleSheet.timeTitle[StyleSheet.WIDTH]; height:StyleSheet.timeTitle[StyleSheet.HEIGHT];color:StyleSheet.timeTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.timeTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.timeTitle[StyleSheet.PIXELSIZE];
            id:timeTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("RouteTime")
        }

        Text {
            x:StyleSheet.timeValue[StyleSheet.X]; y:StyleSheet.timeValue[StyleSheet.Y]; width:StyleSheet.timeValue[StyleSheet.WIDTH]; height:StyleSheet.timeValue[StyleSheet.HEIGHT];color:StyleSheet.timeValue[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.timeValue[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.timeValue[StyleSheet.PIXELSIZE];
            id:timeValue
            wrapMode: Text.WordWrap
            style: Text.Sunken;
            smooth: true
        }

        StdButton {
            source:StyleSheet.show_route_on_map[StyleSheet.SOURCE]; x:StyleSheet.show_route_on_map[StyleSheet.X]; y:StyleSheet.show_route_on_map[StyleSheet.Y]; width:StyleSheet.show_route_on_map[StyleSheet.WIDTH]; height:StyleSheet.show_route_on_map[StyleSheet.HEIGHT];
            id: show_route_on_map
            explode:false; disabled:true; next:show_route_in_list; prev:back
            onClicked: {
                disconnectSignals();
                Genivi.data["mapback"]="NavigationCalculatedRoute";
                Genivi.data["show_route_handle"]=Genivi.routing_handle(dbusIf);
                Genivi.data["zoom_route_handle"]=Genivi.routing_handle(dbusIf);
                pageOpen("NavigationBrowseMap");
            }
        }
        StdButton {
            source:StyleSheet.show_route_in_list[StyleSheet.SOURCE]; x:StyleSheet.show_route_in_list[StyleSheet.X]; y:StyleSheet.show_route_in_list[StyleSheet.Y]; width:StyleSheet.show_route_in_list[StyleSheet.WIDTH]; height:StyleSheet.show_route_in_list[StyleSheet.HEIGHT];
            id:show_route_in_list;
            page:"NavigationRouteDescription";
            explode:false; disabled:true; next:back; prev:show_route_on_map
        }

        StdButton {
            source:StyleSheet.guidance_start[StyleSheet.SOURCE]; x:StyleSheet.guidance_start[StyleSheet.X]; y:StyleSheet.guidance_start[StyleSheet.Y]; width:StyleSheet.guidance_start[StyleSheet.WIDTH]; height:StyleSheet.guidance_start[StyleSheet.HEIGHT];textColor:StyleSheet.startText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.startText[StyleSheet.PIXELSIZE];
            id:guidance_start; text: Genivi.gettext("On");explode:false; disabled:true; next:guidance_stop; prev:show_route_on_map
            onClicked: {
                disconnectSignals();
                Genivi.guidance_message(dbusIf,"StartGuidance",Genivi.routing_handle(dbusIf));
                Genivi.data["mapback"]="NavigationCalculatedRoute";
                Genivi.data["show_route_handle"]=Genivi.routing_handle(dbusIf);
                Genivi.data["show_current_position"]=true;
                pageOpen("NavigationBrowseMap");
            }
        }
        StdButton {
            source:StyleSheet.guidance_stop[StyleSheet.SOURCE]; x:StyleSheet.guidance_stop[StyleSheet.X]; y:StyleSheet.guidance_stop[StyleSheet.Y]; width:StyleSheet.guidance_stop[StyleSheet.WIDTH]; height:StyleSheet.guidance_stop[StyleSheet.HEIGHT];textColor:StyleSheet.stopText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.stopText[StyleSheet.PIXELSIZE];
            id:guidance_stop;text: Genivi.gettext("Off");explode:false; disabled:true; next:show_route_on_map; prev:guidance_start
            onClicked: {
                Genivi.guidance_message(dbusIf,"StopGuidance",[]);
                guidance_start.disabled=false;
                guidance_stop.disabled=true;
            }
        }
        StdButton { source:StyleSheet.back[StyleSheet.SOURCE]; x:StyleSheet.back[StyleSheet.X]; y:StyleSheet.back[StyleSheet.Y]; width:StyleSheet.back[StyleSheet.WIDTH]; height:StyleSheet.back[StyleSheet.HEIGHT];textColor:StyleSheet.backText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.backText[StyleSheet.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); disabled:false; next:show_route_on_map; prev:show_route_in_list;
            onClicked: {
                disconnectSignals();
                pageOpen("NavigationRoute");
            }
        }
    }

	Component.onCompleted: {
		//console.log(Genivi.data);
		connectSignals();
		if (Genivi.data["calculate_route"]) {
			Genivi.routing_message(dbusIf,"CalculateRoute",[]);
			delete(Genivi.data["calculate_route"]);
		} else {
			routeCalculationSuccessful("dummy");
		}
		updateStartStop();
	}
}
