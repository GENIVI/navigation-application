/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file TripComputer.qml
*
* \brief This file is part of the FSA hmi.
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
import "Core/style-sheets/trip-computer-menu-css.js" as StyleSheet;

HMIMenu {
	id: menu
	text: Genivi.gettext("TripComputer")

	DBusIf {
		id: dbusIf
	}

    function hideAll()
    {
        avg_speed_value.visible=false
        avg_speed_unit.visible=false
        avg_speed_title.visible=false
        avg_fuel_value.visible=false
        avg_fuel_unit.visible=false
        avg_fuel_title.visible=false
        distance_value.visible=false
        distance_unit.visible=false
        distance_title.visible=false
        fuel_value.visible=false
        fuel_unit.visible=false
        fuel_title.visible=false
        tank_distance_value.visible=false
        tank_distance_unit.visible=false
        tank_distance_title.visible=false
        predictive_tank_distance_value.visible=false
        predictive_tank_distance_unit.visible=false
        predictive_tank_distance_title.visible=false
        select_trip1.visible=false;
        select_trip2.visible=false;
        select_instant.visible=false;
        reset.visible=false;
    }


    function updateTripMode()
    {
        hideAll()
        if (Genivi.tripMode=="TRIP_NUMBER1")
        {
            content.image=StyleSheet.trip1_background[StyleSheet.SOURCE]
            avg_speed_value.visible=true
            avg_speed_unit.visible=true
            avg_speed_title.visible=true
            avg_fuel_value.visible=true
            avg_fuel_unit.visible=true
            avg_fuel_title.visible=true
            distance_value.visible=true
            distance_unit.visible=true
            distance_title.visible=true
            select_trip2.visible=true;
            select_instant.visible=true;
            reset.visible=true;
            update(1);
        }
        else
        if (Genivi.tripMode=="TRIP_NUMBER2")
        {
            content.image=StyleSheet.trip2_background[StyleSheet.SOURCE]
            avg_speed_value.visible=true
            avg_speed_unit.visible=true
            avg_speed_title.visible=true
            avg_fuel_value.visible=true
            avg_fuel_unit.visible=true
            avg_fuel_title.visible=true
            distance_value.visible=true
            distance_unit.visible=true
            distance_title.visible=true
            select_trip1.visible=true;
            select_instant.visible=true;
            reset.visible=true;
            update(2);
        }
        else
        if (Genivi.tripMode=="TRIP_INSTANT")
        {
            content.image=StyleSheet.trip_instant_background[StyleSheet.SOURCE]
            fuel_value.visible=true
            fuel_unit.visible=true
            fuel_title.visible=true
            tank_distance_value.visible=true
            tank_distance_unit.visible=true
            tank_distance_title.visible=true
            predictive_tank_distance_value.visible=true
            predictive_tank_distance_unit.visible=true
            predictive_tank_distance_title.visible=true
            select_trip1.visible=true;
            select_trip2.visible=true;
            update(0);
        }
        else
        {
            content.image="trip1-background"
            avg_speed_value.visible=true
            avg_speed_unit.visible=true
            avg_speed_title.visible=true
            avg_fuel_value.visible=true
            avg_fuel_unit.visible=true
            avg_fuel_title.visible=true
            distance_value.visible=true
            distance_unit.visible=true
            distance_title.visible=true
            select_trip2.visible=true;
            select_instant.visible=true;
            reset.visible=true;
        }
    }

	function update(tripnr)
    {
		if (tripnr > 0) {
			var res=Genivi.fuel_stop_advisor_message(dbusIf,"GetTripData",["uint8",tripnr-1]);
			// Genivi.dump("",res);
			for (var i = 0 ; i < res[1].length ; i+=4) {
				if (res[1][i+1] == Genivi.FUELSTOPADVISOR_ODOMETER) {
			distance_value.text=res[1][i+3][1]/10;
					distance_unit.text="km";
				}
				if (res[1][i+1] == Genivi.FUELSTOPADVISOR_AVERAGE_SPEED) {
			avg_speed_value.text=res[1][i+3][1]/10;
					avg_speed_unit.text="km/h";
				}
				if (res[1][i+1] == Genivi.FUELSTOPADVISOR_AVERAGE_FUEL_CONSUMPTION_PER_DISTANCE) {
			avg_fuel_value.text=res[1][i+3][1]/10;
					avg_fuel_unit.text="l/100km";
				}
			}
		} else {
			// var res=Genivi.fuel_stop_advisor_message(dbusIf,"GetInstantData",[]);
			if (Genivi.g_routing_handle) {
				Genivi.fuel_stop_advisor_message(dbusIf,"SetRouteHandle",Genivi.g_routing_handle);
			} else {
				Genivi.fuel_stop_advisor_message(dbusIf,"SetRouteHandle","uint32",0);
			}
			var res=Genivi.fuel_stop_advisor_message(dbusIf,"GetGlobalData",[]);
			for (var i = 0 ; i < res[1].length ; i+=4) {
				if (res[1][i+1] == Genivi.FUELSTOPADVISOR_FUEL_LEVEL) {
					fuel_value.text=res[1][i+3][1];
					fuel_unit.text="L";
				}
				if (res[1][i+1] == Genivi.FUELSTOPADVISOR_TANK_DISTANCE) {
        				tank_distance_value.text=res[1][i+3][1];
					tank_distance_unit.text="km";
				}
				if (res[1][i+1] == Genivi.FUELSTOPADVISOR_ENHANCED_TANK_DISTANCE) {
					predictive_tank_distance_value.text=res[1][i+3][1];
					predictive_tank_distance_unit.text="km";
				}
			}

		}
    }
    headlineFg: "grey"
    headlineBg: "blue"
	HMIBgImage {
        id:content
		anchors { fill: parent; topMargin: parent.headlineHeight}
        Text {
            x:StyleSheet.avg_speed_value[StyleSheet.X]; y:StyleSheet.avg_speed_value[StyleSheet.Y]; width:StyleSheet.avg_speed_value[StyleSheet.WIDTH]; height:StyleSheet.avg_speed_value[StyleSheet.HEIGHT];color:StyleSheet.avg_speed_value[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.avg_speed_value[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.avg_speed_value[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_speed_value
            text: " "
        }
        Text {
            x:StyleSheet.avg_speed_unit[StyleSheet.X]; y:StyleSheet.avg_speed_unit[StyleSheet.Y]; width:StyleSheet.avg_speed_unit[StyleSheet.WIDTH]; height:StyleSheet.avg_speed_unit[StyleSheet.HEIGHT];color:StyleSheet.avg_speed_unit[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.avg_speed_unit[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.avg_speed_unit[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_speed_unit
            text: " "
        }
        Text {
            x:StyleSheet.avg_speed_title[StyleSheet.X]; y:StyleSheet.avg_speed_title[StyleSheet.Y]; width:StyleSheet.avg_speed_title[StyleSheet.WIDTH]; height:StyleSheet.avg_speed_title[StyleSheet.HEIGHT];color:StyleSheet.avg_speed_title[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.avg_speed_title[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.avg_speed_title[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_speed_title
            text: Genivi.gettext("AvgSpeed")
        }
        Text {
            x:StyleSheet.avg_fuel_value[StyleSheet.X]; y:StyleSheet.avg_fuel_value[StyleSheet.Y]; width:StyleSheet.avg_fuel_value[StyleSheet.WIDTH]; height:StyleSheet.avg_fuel_value[StyleSheet.HEIGHT];color:StyleSheet.avg_fuel_value[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.avg_fuel_value[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.avg_fuel_value[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_fuel_value
            text: " "
        }
        Text {
            x:StyleSheet.avg_fuel_unit[StyleSheet.X]; y:StyleSheet.avg_fuel_unit[StyleSheet.Y]; width:StyleSheet.avg_fuel_unit[StyleSheet.WIDTH]; height:StyleSheet.avg_fuel_unit[StyleSheet.HEIGHT];color:StyleSheet.avg_fuel_unit[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.avg_fuel_unit[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.avg_fuel_unit[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_fuel_unit
            text: " "
        }
        Text {
            x:StyleSheet.avg_fuel_title[StyleSheet.X]; y:StyleSheet.avg_fuel_title[StyleSheet.Y]; width:StyleSheet.avg_fuel_title[StyleSheet.WIDTH]; height:StyleSheet.avg_fuel_title[StyleSheet.HEIGHT];color:StyleSheet.avg_fuel_title[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.avg_fuel_title[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.avg_fuel_title[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_fuel_title
            text: Genivi.gettext("AvgFuel")
        }
        Text {
            x:StyleSheet.distance_value[StyleSheet.X]; y:StyleSheet.distance_value[StyleSheet.Y]; width:StyleSheet.distance_value[StyleSheet.WIDTH]; height:StyleSheet.distance_value[StyleSheet.HEIGHT];color:StyleSheet.distance_value[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.distance_value[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.distance_value[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:distance_value
            text: " "
        }
        Text {
            x:StyleSheet.distance_unit[StyleSheet.X]; y:StyleSheet.distance_unit[StyleSheet.Y]; width:StyleSheet.distance_unit[StyleSheet.WIDTH]; height:StyleSheet.distance_unit[StyleSheet.HEIGHT];color:StyleSheet.distance_unit[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.distance_unit[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.distance_unit[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:distance_unit
            text: " "
        }
        Text {
            x:StyleSheet.distance_title[StyleSheet.X]; y:StyleSheet.distance_title[StyleSheet.Y]; width:StyleSheet.distance_title[StyleSheet.WIDTH]; height:StyleSheet.distance_title[StyleSheet.HEIGHT];color:StyleSheet.distance_title[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.distance_title[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.distance_title[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:distance_title
            text: Genivi.gettext("Distance")
        }
        Text {
            x:StyleSheet.fuel_value[StyleSheet.X]; y:StyleSheet.fuel_value[StyleSheet.Y]; width:StyleSheet.fuel_value[StyleSheet.WIDTH]; height:StyleSheet.fuel_value[StyleSheet.HEIGHT];color:StyleSheet.fuel_value[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.fuel_value[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.fuel_value[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:fuel_value
            text: " "
        }
        Text {
            x:StyleSheet.fuel_unit[StyleSheet.X]; y:StyleSheet.fuel_unit[StyleSheet.Y]; width:StyleSheet.fuel_unit[StyleSheet.WIDTH]; height:StyleSheet.v[StyleSheet.HEIGHT];color:StyleSheet.fuel_unit[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.fuel_unit[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.fuel_unit[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:fuel_unit
            text: " "
        }
        Text {
            x:StyleSheet.fuel_title[StyleSheet.X]; y:StyleSheet.fuel_title[StyleSheet.Y]; width:StyleSheet.fuel_title[StyleSheet.WIDTH]; height:StyleSheet.fuel_title[StyleSheet.HEIGHT];color:StyleSheet.fuel_title[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.fuel_title[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.fuel_title[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:fuel_title
            text: Genivi.gettext("FuelLevel")
        }
        Text {
            x:StyleSheet.tank_distance_value[StyleSheet.X]; y:StyleSheet.tank_distance_value[StyleSheet.Y]; width:StyleSheet.tank_distance_value[StyleSheet.WIDTH]; height:StyleSheet.tank_distance_value[StyleSheet.HEIGHT];color:StyleSheet.tank_distance_value[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.tank_distance_value[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.tank_distance_value[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:tank_distance_value
            text: " "
        }
        Text {
            x:StyleSheet.tank_distance_unit[StyleSheet.X]; y:StyleSheet.tank_distance_unit[StyleSheet.Y]; width:StyleSheet.tank_distance_unit[StyleSheet.WIDTH]; height:StyleSheet.tank_distance_unit[StyleSheet.HEIGHT];color:StyleSheet.tank_distance_unit[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.tank_distance_unit[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.tank_distance_unit[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:tank_distance_unit
            text: " "
        }
        Text {
            x:StyleSheet.tank_distance_title[StyleSheet.X]; y:StyleSheet.tank_distance_title[StyleSheet.Y]; width:StyleSheet.tank_distance_title[StyleSheet.WIDTH]; height:StyleSheet.tank_distance_title[StyleSheet.HEIGHT];color:StyleSheet.tank_distance_title[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.tank_distance_title[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.tank_distance_title[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:tank_distance_title
            text: Genivi.gettext("TankDistance")
        }
        Text {
            x:StyleSheet.predictive_tank_distance_value[StyleSheet.X]; y:StyleSheet.predictive_tank_distance_value[StyleSheet.Y]; width:StyleSheet.predictive_tank_distance_value[StyleSheet.WIDTH]; height:StyleSheet.predictive_tank_distance_value[StyleSheet.HEIGHT];color:StyleSheet.predictive_tank_distance_value[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.predictive_tank_distance_value[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.predictive_tank_distance_value[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:predictive_tank_distance_value
            text: " "
        }
        Text {
            x:StyleSheet.predictive_tank_distance_unit[StyleSheet.X]; y:StyleSheet.predictive_tank_distance_unit[StyleSheet.Y]; width:StyleSheet.predictive_tank_distance_unit[StyleSheet.WIDTH]; height:StyleSheet.predictive_tank_distance_unit[StyleSheet.HEIGHT];color:StyleSheet.predictive_tank_distance_unit[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.predictive_tank_distance_unit[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.predictive_tank_distance_unit[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:predictive_tank_distance_unit
            text: " "
        }
        Text {
            x:StyleSheet.predictive_tank_distance_title[StyleSheet.X]; y:StyleSheet.predictive_tank_distance_title[StyleSheet.Y]; width:StyleSheet.v[StyleSheet.WIDTH]; height:StyleSheet.predictive_tank_distance_title[StyleSheet.HEIGHT];color:StyleSheet.predictive_tank_distance_title[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.predictive_tank_distance_title[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.predictive_tank_distance_title[StyleSheet.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:predictive_tank_distance_title
            text: Genivi.gettext("PredictiveTankDistance")
        }

        StdButton { source:StyleSheet.reset[StyleSheet.SOURCE]; x:StyleSheet.reset[StyleSheet.X]; y:StyleSheet.reset[StyleSheet.Y]; width:StyleSheet.reset[StyleSheet.WIDTH]; height:StyleSheet.reset[StyleSheet.HEIGHT];textColor:StyleSheet.resetText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.resetText[StyleSheet.PIXELSIZE];
            visible: false;
            id:reset; text: Genivi.gettext("Reset"); explode:false; disabled:false; next:select_trip1; prev:back;
            onClicked:{
		if (Genivi.tripMode == "TRIP_NUMBER1") {
			Genivi.fuel_stop_advisor_message(dbusIf,"ResetTripData",["uint8",0]);
		}
		if (Genivi.tripMode == "TRIP_NUMBER2") {
			Genivi.fuel_stop_advisor_message(dbusIf,"ResetTripData",["uint8",1]);
		}
    		updateTripMode();
            }
        }
        StdButton { source:StyleSheet.select_trip1[StyleSheet.SOURCE]; x:StyleSheet.select_trip1[StyleSheet.X]; y:StyleSheet.select_trip1[StyleSheet.Y]; width:StyleSheet.select_trip1[StyleSheet.WIDTH]; height:StyleSheet.select_trip1[StyleSheet.HEIGHT];
            visible: false;
            id:select_trip1; explode:false; disabled:false; next:select_trip2; prev:reset;
            onClicked:{
                Genivi.tripMode="TRIP_NUMBER1";
                updateTripMode();
            }
        }
        StdButton { source:StyleSheet.select_trip2[StyleSheet.SOURCE]; x:StyleSheet.select_trip2[StyleSheet.X]; y:StyleSheet.select_trip2[StyleSheet.Y]; width:StyleSheet.select_trip2[StyleSheet.WIDTH]; height:StyleSheet.select_trip2[StyleSheet.HEIGHT];
            visible: false;
            id:select_trip2; explode:false; disabled:false; next:select_instant; prev:select_trip1;
            onClicked:{
                Genivi.tripMode="TRIP_NUMBER2";
                updateTripMode();
            }
        }
        StdButton { source:StyleSheet.select_instant[StyleSheet.SOURCE]; x:StyleSheet.select_instant[StyleSheet.X]; y:StyleSheet.select_instant[StyleSheet.Y]; width:StyleSheet.select_instant[StyleSheet.WIDTH]; height:StyleSheet.select_instant[StyleSheet.HEIGHT];
            visible: false;
            id:select_instant; explode:false; disabled:false; next:back; prev:select_trip2;
            onClicked:{
                Genivi.tripMode="TRIP_INSTANT";
                updateTripMode();
            }
        }
        StdButton { source:StyleSheet.back[StyleSheet.SOURCE]; x:StyleSheet.back[StyleSheet.X]; y:StyleSheet.back[StyleSheet.Y]; width:StyleSheet.back[StyleSheet.WIDTH]; height:StyleSheet.back[StyleSheet.HEIGHT];textColor:StyleSheet.backText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.backText[StyleSheet.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); explode:false; disabled:false; next:reset; prev:select_instant; page:"MainMenu"}
    }
    Component.onCompleted: {
        updateTripMode();
    }
}
