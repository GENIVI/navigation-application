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
import QtQuick 1.0
import "Core"
import "Core/genivi.js" as Genivi;

HMIMenu {
	id: menu
    headlineFg: "grey"
    headlineBg: "blue"
    text: Genivi.gettext("NavigationCalculatedRoute")
	next: back
	prev: description
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
		console.log("routeCalculationProgressUpdate:");
		Genivi.dump("",args);

        menu.text=Genivi.gettext("CalculatedRouteInProgress")+ " "+args[7]+"%";
	}

	function updateStartStop()
	{
		var res=Genivi.nav_message(dbusIf,"Guidance","GetGuidanceStatus",[]);
		//Genivi.dump("",res);
		if (res[0] == "uint16" && res[1] != Genivi.NAVIGATIONCORE_INACTIVE) {
			start.disabled=true;
			stop.disabled=false;
		} else {
			start.disabled=false;
			stop.disabled=true;
		}
	}

	function routeCalculationSuccessful(args)
	{
        console.log("routeCalculationSuccessful:");
		show.disabled=false;
		description.disabled=false;
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

            routeDistanceValue.text =Genivi.distance(distance);
            routeTimeValue.text= Genivi.time(time);

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
        image:"navigation-calculated-route-menu-background";
        anchors { fill: parent; topMargin: parent.headlineHeight}
        //Important notice: x,y coordinates from the left/top origin of the component
        //so take in account the header height and substract it

        Text {
            height:menu.hspc
            x:532; y:36;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("Guidance")
        }

        Text {
            height:menu.hspc
            x:500; y:202;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("DisplayRoute")
        }


        Text {
            height:menu.hspc
            x:52; y:22;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("RouteDistance")
        }

        Text {
            id:routeDistanceValue
            height:menu.hspc
            width: 200
            wrapMode: Text.WordWrap
            x:52; y:52;
            font.pixelSize: 32;
            style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true
        }

        Text {
            height:menu.hspc
            x:52; y:116;
            font.pixelSize: 25;
            style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
            text: Genivi.gettext("RouteTime")
        }

        Text {
            id:routeTimeValue
            height:menu.hspc
            width: 200
            wrapMode: Text.WordWrap
            x:52; y:150;
            font.pixelSize: 32;
            style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true
        }

        StdButton {
            source:"Core/images/show-route-on-map.png";
            x:482; y:246; width:100; height:60;
            id: show
            explode:false; disabled:true; next:start; prev:back
            onClicked: {
                disconnectSignals();
                Genivi.data["mapback"]="NavigationCalculatedRoute";
                Genivi.data["show_route_handle"]=Genivi.routing_handle(dbusIf);
                Genivi.data["zoom_route_handle"]=Genivi.routing_handle(dbusIf);
                pageOpen("NavigationBrowseMap");
            }
        }
        StdButton {
            source:"Core/images/show-route-in-list.png";
            x:612; y:246; width:100; height:60;
            id:description;
            page:"NavigationRouteDescription";
            explode:false; disabled:true; next:back; prev:stop
        }

        StdButton {
            source:"Core/images/guidance-on.png";
            x:482; y:78; width:100; height:60;
            textColor:"black"; pixelSize:38; text: Genivi.gettext("On");
            id:start; explode:false; disabled:true; next:stop; prev:show
            onClicked: {
                disconnectSignals();
                console.log("StartGuidance");
                Genivi.guidance_message(dbusIf,"StartGuidance",Genivi.routing_handle(dbusIf));
                console.log("StartGuidance done");
                Genivi.data["mapback"]="NavigationCalculatedRoute";
                Genivi.data["show_route_handle"]=Genivi.routing_handle(dbusIf);
                Genivi.data["show_current_position"]=true;
                pageOpen("NavigationBrowseMap");
            }
        }
        StdButton {
            source:"Core/images/guidance-off.png";
            x:612; y:78; width:100; height:60;
            textColor:"black"; pixelSize:38; text: Genivi.gettext("Off");
            id:stop;explode:false; disabled:true; next:description; prev:start
            onClicked: {
                Genivi.guidance_message(dbusIf,"StopGuidance",[]);
                start.disabled=false;
                stop.disabled=true;
            }
        }
        StdButton { textColor:"black"; pixelSize:38 ; source:"Core/images/back.png"; x:600; y:374; width:180; height:60; id:back; text: Genivi.gettext("Back"); disabled:false; next:show; prev:calculate_curr;
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
