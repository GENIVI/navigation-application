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

HMIMenu {
	id: menu
	text: Genivi.gettext("TripComputer")
    function hideAll()
    {
        avg_speed.visible=false
        avg_speed_unit.visible=false
        avg_speed_title.visible=false
        avg_fuel.visible=false
        avg_fuel_unit.visible=false
        avg_fuel_title.visible=false
        distance.visible=false
        distance_unit.visible=false
        distance_title.visible=false
        fuel.visible=false
        fuel_unit.visible=false
        fuel_title.visible=false
        tank_distance.visible=false
        tank_distance_unit.visible=false
        tank_distance_title.visible=false
        predictive_tank_distance.visible=false
        predictive_tank_distance_unit.visible=false
        predictive_tank_distance_title.visible=false
        trip1.visible=false;
        trip2.visible=false;
        instant.visible=false;
        reset.visible=false;
    }

    function updateTripMode()
    {
        hideAll()
        if (Genivi.tripMode=="TRIP_NUMBER1")
        {
            content.image="trip1-background"
            avg_speed.visible=true
            avg_speed_unit.visible=true
            avg_speed_title.visible=true
            avg_fuel.visible=true
            avg_fuel_unit.visible=true
            avg_fuel_title.visible=true
            distance.visible=true
            distance_unit.visible=true
            distance_title.visible=true
            trip2.visible=true;
            instant.visible=true;
            reset.visible=true;
        }
        else
        if (Genivi.tripMode=="TRIP_NUMBER2")
        {
            content.image="trip2-background"
            avg_speed.visible=true
            avg_speed_unit.visible=true
            avg_speed_title.visible=true
            avg_fuel.visible=true
            avg_fuel_unit.visible=true
            avg_fuel_title.visible=true
            distance.visible=true
            distance_unit.visible=true
            distance_title.visible=true
            trip1.visible=true;
            instant.visible=true;
            reset.visible=true;
        }
        else
        if (Genivi.tripMode=="TRIP_INSTANT")
        {
            content.image="trip-instant-background"
            fuel.visible=true
            fuel_unit.visible=true
            fuel_title.visible=true
            tank_distance.visible=true
            tank_distance_unit.visible=true
            tank_distance_title.visible=true
            predictive_tank_distance.visible=true
            predictive_tank_distance_unit.visible=true
            predictive_tank_distance_title.visible=true
            trip1.visible=true;
            trip2.visible=true;
        }
        else
        {
            content.image="trip1-background"
            avg_speed.visible=true
            avg_speed_unit.visible=true
            avg_speed_title.visible=true
            avg_fuel.visible=true
            avg_fuel_unit.visible=true
            avg_fuel_title.visible=true
            distance.visible=true
            distance_unit.visible=true
            distance_title.visible=true
            trip2.visible=true;
            instant.visible=true;
            reset.visible=true;
        }
    }

	function update()
    { //just to populate with default values
		avg_speed.text="58";
		avg_speed_unit.text="km/h"
		avg_fuel.text="5.7";
		avg_fuel_unit.text="L/100"
		distance.text="129";
		distance_unit.text="km";
        fuel.text="35";
        fuel_unit.text="L";
        tank_distance.text="540";
        tank_distance_unit.text="km";
        predictive_tank_distance.text="647";
        predictive_tank_distance_unit.text="km";
    }
    headlineFg: "grey"
    headlineBg: "blue"
	HMIBgImage {
        id:content
//Important notice: x,y coordinates from the left/top origin, so take in account the header of 26 pixels high
		anchors { fill: parent; topMargin: parent.headlineHeight}
		Text {
				id:avg_speed
                visible: false
                height:menu.hspc
				x:72; y:14;
                font.pixelSize: 86;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: " "
          	 }
		Text {
				id:avg_speed_unit
                visible: false
                height:menu.hspc
				x:72; y:114;
                font.pixelSize: 42;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: " "
          	 }
		Text {
                id:avg_speed_title
                visible: false
                height:menu.hspc
				x:72; y:294;
                font.pixelSize: 25;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: Genivi.gettext("AvgSpeed")
             }
		Text {
				id:avg_fuel
                visible: false
                height:menu.hspc
				x:312; y:14;
                font.pixelSize: 86;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: " "
          	 }
		Text {
				id:avg_fuel_unit
                visible: false
                height:menu.hspc
				x:312; y:114;
                font.pixelSize: 42;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: " "
          	 }
		Text {
                id:avg_fuel_title
                visible: false
                height:menu.hspc
				x:312; y:294;
                font.pixelSize: 25;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: Genivi.gettext("AvgFuel")
             }
		Text {
				id:distance
                visible: false
                height:menu.hspc
				x:552; y:14;
                font.pixelSize: 86;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: " "
          	 }
		Text {
				id:distance_unit
                visible: false
                height:menu.hspc
				x:552; y:114;
                font.pixelSize: 42;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: " "
          	 }
		Text {
                id:distance_title
                visible: false
                height:menu.hspc
				x:552; y:294;
                font.pixelSize: 25;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: Genivi.gettext("Distance")
             }

        Text {
                id:fuel
                visible: false
                height:menu.hspc
                x:72; y:14;
                font.pixelSize: 86;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: " "
             }
        Text {
                id:fuel_unit
                visible: false
                height:menu.hspc
                x:72; y:114;
                font.pixelSize: 42;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: " "
             }
        Text {
                id:fuel_title
                visible: false
                height:menu.hspc
                x:72; y:294;
                font.pixelSize: 25;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: Genivi.gettext("FuelLevel")
             }
        Text {
                id:tank_distance
                visible: false
                height:menu.hspc
                x:312; y:14;
                font.pixelSize: 86;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: " "
             }
        Text {
                id:tank_distance_unit
                visible: false
                height:menu.hspc
                x:312; y:114;
                font.pixelSize: 42;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: " "
             }
        Text {
                id:tank_distance_title
                visible: false
                height:menu.hspc
                x:312; y:294;
                font.pixelSize: 25;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: Genivi.gettext("TankDistance")
             }
        Text {
                id:predictive_tank_distance
                visible: false
                height:menu.hspc
                x:552; y:14;
                font.pixelSize: 86;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: " "
             }
        Text {
                id:predictive_tank_distance_unit
                visible: false
                height:menu.hspc
                x:552; y:114;
                font.pixelSize: 42;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: " "
             }
        Text {
                id:predictive_tank_distance_title
                visible: false
                height:menu.hspc
                x:552; y:294;
                font.pixelSize: 25;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
                text: Genivi.gettext("PredictiveTankDistance")
             }

        StdButton { textColor:"red"; pixelSize:38 ; source:"Core/images/reset.png"; visible: false; x:20; y:374; width:180; height:60; id:reset; text: Genivi.gettext("Reset"); explode:false; disabled:false; next:trip1; prev:back;
            onClicked:{
            }
        }
        StdButton { source:"Core/images/select-trip1.png"; visible: false; x:225; y:374; width:100; height:60; id:trip1; explode:false; disabled:false; next:trip2; prev:reset;
            onClicked:{
                Genivi.tripMode="TRIP_NUMBER1";
                updateTripMode();
            }
        }
        StdButton { source:"Core/images/select-trip2.png"; visible: false; x:350; y:374; width:100; height:60; id:trip2; explode:false; disabled:false; next:instant; prev:trip1;
            onClicked:{
                Genivi.tripMode="TRIP_NUMBER2";
                updateTripMode();
            }
        }
        StdButton { source:"Core/images/select-instant.png"; visible: false; x:475; y:374; width:100; height:60; id:instant; explode:false; disabled:false; next:back; prev:trip2;
            onClicked:{
                Genivi.tripMode="TRIP_INSTANT";
                updateTripMode();
            }
        }
        StdButton { textColor:"black"; pixelSize:38 ; source:"Core/images/back.png"; x:600; y:374; width:180; height:60; id:back; text: Genivi.gettext("Back"); explode:false; disabled:false; next:reset; prev:instant; page:"MainMenu"}
	}
	Component.onCompleted: {
        updateTripMode();
		update();
	}
}
