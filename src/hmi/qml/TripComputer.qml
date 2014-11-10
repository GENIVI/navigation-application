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
import QtQuick 2.1 
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/trip-computer-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    property Item tripDataUpdatedSignal;

	DBusIf {
		id: dbusIf
	}

    function tripDataUpdated(args)
    {
        updateTripMode();
    }

    function connectSignals()
    {
        tripDataUpdatedSignal=dbusIf.connect("","/org/genivi/demonstrator/FuelStopAdvisor","org.genivi.demonstrator.FuelStopAdvisor","TripDataUpdated",menu,"tripDataUpdated");
    }

    function disconnectSignals()
    {
        tripDataUpdatedSignal.destroy();
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
            content.image=StyleSheet.trip1_background[Constants.SOURCE]
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
            content.image=StyleSheet.trip2_background[Constants.SOURCE]
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
            content.image=StyleSheet.trip_instant_background[Constants.SOURCE]
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
            content.image=StyleSheet.trip1_background[Constants.SOURCE]
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

    function disableAllValue()
    {
        distance_value.text="---";
        avg_speed_value.text="---";
        avg_fuel_value.text="---";
        fuel_value.text="---";
        tank_distance_value.text="---";
        predictive_tank_distance_value.text="---";
    }

    function setUnits()
    {
        distance_unit.text="km";
        avg_speed_unit.text="km/h";
        avg_fuel_unit.text="l/100km";
        fuel_unit.text="L";
        tank_distance_unit.text="km";
        predictive_tank_distance_unit.text="km";
    }

	function update(tripnr)
    {
        var res;
        disableAllValue(); // By default set all the values to "--"
		if (tripnr > 0) {         
            res=Genivi.fuel_stop_advisor_message(dbusIf,"GetTripData",["uint8",tripnr-1]);
			Genivi.dump("",res);
			for (var i = 0 ; i < res[1].length ; i+=4) {
                if (res[1][i+1] == Genivi.FUELSTOPADVISOR_DISTANCE) {
			distance_value.text=res[1][i+3][1]/10;
				}
				if (res[1][i+1] == Genivi.FUELSTOPADVISOR_AVERAGE_SPEED) {
			avg_speed_value.text=res[1][i+3][1]/10;
				}
				if (res[1][i+1] == Genivi.FUELSTOPADVISOR_AVERAGE_FUEL_CONSUMPTION_PER_DISTANCE) {
			avg_fuel_value.text=res[1][i+3][1]/10;
				}
			}
		} else {
            res=Genivi.fuel_stop_advisor_message(dbusIf,"GetInstantData",[]);
			for (var i = 0 ; i < res[1].length ; i+=4) {
				if (res[1][i+1] == Genivi.FUELSTOPADVISOR_FUEL_LEVEL) {
					fuel_value.text=res[1][i+3][1];
				}
				if (res[1][i+1] == Genivi.FUELSTOPADVISOR_TANK_DISTANCE) {
        				tank_distance_value.text=res[1][i+3][1];
				}
				if (res[1][i+1] == Genivi.FUELSTOPADVISOR_ENHANCED_TANK_DISTANCE) {
					predictive_tank_distance_value.text=res[1][i+3][1];
				}
			}

		}
    }

    function leave()
    {
        disconnectSignals();
    }

	HMIBgImage {
        id:content
        image:
        {
            if (Genivi.tripMode=="TRIP_NUMBER1")
            {
                image=StyleSheet.trip1_background[Constants.SOURCE]
            }
            else
            if (Genivi.tripMode=="TRIP_NUMBER2")
            {
                image=StyleSheet.trip2_background[Constants.SOURCE]
            }
            else
            if (Genivi.tripMode=="TRIP_INSTANT")
            {
                image=StyleSheet.trip_instant_background[Constants.SOURCE]
            }
            else
            {
                image=StyleSheet.trip1_background[Constants.SOURCE]
            }
        }

		anchors { fill: parent; topMargin: parent.headlineHeight}
        Text {
            x:StyleSheet.avg_speed_value[Constants.X]; y:StyleSheet.avg_speed_value[Constants.Y]; width:StyleSheet.avg_speed_value[Constants.WIDTH]; height:StyleSheet.avg_speed_value[Constants.HEIGHT];color:StyleSheet.avg_speed_value[Constants.TEXTCOLOR];styleColor:StyleSheet.avg_speed_value[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.avg_speed_value[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_speed_value
            text: " "
        }
        Text {
            x:StyleSheet.avg_speed_unit[Constants.X]; y:StyleSheet.avg_speed_unit[Constants.Y]; width:StyleSheet.avg_speed_unit[Constants.WIDTH]; height:StyleSheet.avg_speed_unit[Constants.HEIGHT];color:StyleSheet.avg_speed_unit[Constants.TEXTCOLOR];styleColor:StyleSheet.avg_speed_unit[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.avg_speed_unit[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_speed_unit
            text: " "
        }
        Text {
            x:StyleSheet.avg_speed_title[Constants.X]; y:StyleSheet.avg_speed_title[Constants.Y]; width:StyleSheet.avg_speed_title[Constants.WIDTH]; height:StyleSheet.avg_speed_title[Constants.HEIGHT];color:StyleSheet.avg_speed_title[Constants.TEXTCOLOR];styleColor:StyleSheet.avg_speed_title[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.avg_speed_title[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_speed_title
            text: Genivi.gettext("AvgSpeed")
        }
        Text {
            x:StyleSheet.avg_fuel_value[Constants.X]; y:StyleSheet.avg_fuel_value[Constants.Y]; width:StyleSheet.avg_fuel_value[Constants.WIDTH]; height:StyleSheet.avg_fuel_value[Constants.HEIGHT];color:StyleSheet.avg_fuel_value[Constants.TEXTCOLOR];styleColor:StyleSheet.avg_fuel_value[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.avg_fuel_value[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_fuel_value
            text: " "
        }
        Text {
            x:StyleSheet.avg_fuel_unit[Constants.X]; y:StyleSheet.avg_fuel_unit[Constants.Y]; width:StyleSheet.avg_fuel_unit[Constants.WIDTH]; height:StyleSheet.avg_fuel_unit[Constants.HEIGHT];color:StyleSheet.avg_fuel_unit[Constants.TEXTCOLOR];styleColor:StyleSheet.avg_fuel_unit[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.avg_fuel_unit[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_fuel_unit
            text: " "
        }
        Text {
            x:StyleSheet.avg_fuel_title[Constants.X]; y:StyleSheet.avg_fuel_title[Constants.Y]; width:StyleSheet.avg_fuel_title[Constants.WIDTH]; height:StyleSheet.avg_fuel_title[Constants.HEIGHT];color:StyleSheet.avg_fuel_title[Constants.TEXTCOLOR];styleColor:StyleSheet.avg_fuel_title[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.avg_fuel_title[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:avg_fuel_title
            text: Genivi.gettext("AvgFuel")
        }
        Text {
            x:StyleSheet.distance_value[Constants.X]; y:StyleSheet.distance_value[Constants.Y]; width:StyleSheet.distance_value[Constants.WIDTH]; height:StyleSheet.distance_value[Constants.HEIGHT];color:StyleSheet.distance_value[Constants.TEXTCOLOR];styleColor:StyleSheet.distance_value[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.distance_value[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:distance_value
            text: " "
        }
        Text {
            x:StyleSheet.distance_unit[Constants.X]; y:StyleSheet.distance_unit[Constants.Y]; width:StyleSheet.distance_unit[Constants.WIDTH]; height:StyleSheet.distance_unit[Constants.HEIGHT];color:StyleSheet.distance_unit[Constants.TEXTCOLOR];styleColor:StyleSheet.distance_unit[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.distance_unit[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:distance_unit
            text: " "
        }
        Text {
            x:StyleSheet.distance_title[Constants.X]; y:StyleSheet.distance_title[Constants.Y]; width:StyleSheet.distance_title[Constants.WIDTH]; height:StyleSheet.distance_title[Constants.HEIGHT];color:StyleSheet.distance_title[Constants.TEXTCOLOR];styleColor:StyleSheet.distance_title[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.distance_title[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:distance_title
            text: Genivi.gettext("Distance")
        }
        Text {
            x:StyleSheet.fuel_value[Constants.X]; y:StyleSheet.fuel_value[Constants.Y]; width:StyleSheet.fuel_value[Constants.WIDTH]; height:StyleSheet.fuel_value[Constants.HEIGHT];color:StyleSheet.fuel_value[Constants.TEXTCOLOR];styleColor:StyleSheet.fuel_value[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.fuel_value[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:fuel_value
            text: " "
        }
        Text {
            x:StyleSheet.fuel_unit[Constants.X]; y:StyleSheet.fuel_unit[Constants.Y]; width:StyleSheet.fuel_unit[Constants.WIDTH]; height:StyleSheet.fuel_unit[Constants.HEIGHT];color:StyleSheet.fuel_unit[Constants.TEXTCOLOR];styleColor:StyleSheet.fuel_unit[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.fuel_unit[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:fuel_unit
            text: " "
        }
        Text {
            x:StyleSheet.fuel_title[Constants.X]; y:StyleSheet.fuel_title[Constants.Y]; width:StyleSheet.fuel_title[Constants.WIDTH]; height:StyleSheet.fuel_title[Constants.HEIGHT];color:StyleSheet.fuel_title[Constants.TEXTCOLOR];styleColor:StyleSheet.fuel_title[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.fuel_title[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:fuel_title
            text: Genivi.gettext("FuelLevel")
        }
        Text {
            x:StyleSheet.tank_distance_value[Constants.X]; y:StyleSheet.tank_distance_value[Constants.Y]; width:StyleSheet.tank_distance_value[Constants.WIDTH]; height:StyleSheet.tank_distance_value[Constants.HEIGHT];color:StyleSheet.tank_distance_value[Constants.TEXTCOLOR];styleColor:StyleSheet.tank_distance_value[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.tank_distance_value[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:tank_distance_value
            text: " "
        }
        Text {
            x:StyleSheet.tank_distance_unit[Constants.X]; y:StyleSheet.tank_distance_unit[Constants.Y]; width:StyleSheet.tank_distance_unit[Constants.WIDTH]; height:StyleSheet.tank_distance_unit[Constants.HEIGHT];color:StyleSheet.tank_distance_unit[Constants.TEXTCOLOR];styleColor:StyleSheet.tank_distance_unit[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.tank_distance_unit[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:tank_distance_unit
            text: " "
        }
        Text {
            x:StyleSheet.tank_distance_title[Constants.X]; y:StyleSheet.tank_distance_title[Constants.Y]; width:StyleSheet.tank_distance_title[Constants.WIDTH]; height:StyleSheet.tank_distance_title[Constants.HEIGHT];color:StyleSheet.tank_distance_title[Constants.TEXTCOLOR];styleColor:StyleSheet.tank_distance_title[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.tank_distance_title[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:tank_distance_title
            text: Genivi.gettext("TankDistance")
        }
        Text {
            x:StyleSheet.predictive_tank_distance_value[Constants.X]; y:StyleSheet.predictive_tank_distance_value[Constants.Y]; width:StyleSheet.predictive_tank_distance_value[Constants.WIDTH]; height:StyleSheet.predictive_tank_distance_value[Constants.HEIGHT];color:StyleSheet.predictive_tank_distance_value[Constants.TEXTCOLOR];styleColor:StyleSheet.predictive_tank_distance_value[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.predictive_tank_distance_value[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:predictive_tank_distance_value
            text: " "
        }
        Text {
            x:StyleSheet.predictive_tank_distance_unit[Constants.X]; y:StyleSheet.predictive_tank_distance_unit[Constants.Y]; width:StyleSheet.predictive_tank_distance_unit[Constants.WIDTH]; height:StyleSheet.predictive_tank_distance_unit[Constants.HEIGHT];color:StyleSheet.predictive_tank_distance_unit[Constants.TEXTCOLOR];styleColor:StyleSheet.predictive_tank_distance_unit[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.predictive_tank_distance_unit[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:predictive_tank_distance_unit
            text: " "
        }
        Text {
            x:StyleSheet.predictive_tank_distance_title[Constants.X]; y:StyleSheet.predictive_tank_distance_title[Constants.Y]; width:StyleSheet.predictive_tank_distance_title[Constants.WIDTH]; height:StyleSheet.predictive_tank_distance_title[Constants.HEIGHT];color:StyleSheet.predictive_tank_distance_title[Constants.TEXTCOLOR];styleColor:StyleSheet.predictive_tank_distance_title[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.predictive_tank_distance_title[Constants.PIXELSIZE];
            visible: false
            style: Text.Sunken;
            smooth: true
            id:predictive_tank_distance_title
            text: Genivi.gettext("PredictiveTankDistance")
        }

        StdButton { source:StyleSheet.reset[Constants.SOURCE]; x:StyleSheet.reset[Constants.X]; y:StyleSheet.reset[Constants.Y]; width:StyleSheet.reset[Constants.WIDTH]; height:StyleSheet.reset[Constants.HEIGHT];textColor:StyleSheet.resetText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.resetText[Constants.PIXELSIZE];
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
        StdButton { source:StyleSheet.select_trip1[Constants.SOURCE]; x:StyleSheet.select_trip1[Constants.X]; y:StyleSheet.select_trip1[Constants.Y]; width:StyleSheet.select_trip1[Constants.WIDTH]; height:StyleSheet.select_trip1[Constants.HEIGHT];
            visible: false;
            id:select_trip1; explode:false; disabled:false; next:select_trip2; prev:reset;
            onClicked:{
                Genivi.tripMode="TRIP_NUMBER1";
                updateTripMode();
            }
        }
        StdButton { source:StyleSheet.select_trip2[Constants.SOURCE]; x:StyleSheet.select_trip2[Constants.X]; y:StyleSheet.select_trip2[Constants.Y]; width:StyleSheet.select_trip2[Constants.WIDTH]; height:StyleSheet.select_trip2[Constants.HEIGHT];
            visible: false;
            id:select_trip2; explode:false; disabled:false; next:select_instant; prev:select_trip1;
            onClicked:{
                Genivi.tripMode="TRIP_NUMBER2";
                updateTripMode();
            }
        }
        StdButton { source:StyleSheet.select_instant[Constants.SOURCE]; x:StyleSheet.select_instant[Constants.X]; y:StyleSheet.select_instant[Constants.Y]; width:StyleSheet.select_instant[Constants.WIDTH]; height:StyleSheet.select_instant[Constants.HEIGHT];
            visible: false;
            id:select_instant; explode:false; disabled:false; next:back; prev:select_trip2;
            onClicked:{
                Genivi.tripMode="TRIP_INSTANT";
                updateTripMode();
            }
        }
        StdButton { source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); explode:false; disabled:false; next:reset; prev:select_instant;
            onClicked:{leave(); pageOpen("MainMenu");}
        }
    }
    Component.onCompleted: {
        connectSignals();
        setUnits();
        updateTripMode();
    }
}
