/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file NavigationSettings.qml
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
    text: Genivi.gettext("NavigationSettings")
	next: back
        prev: back
	DBusIf {
		id:dbusIf;
	}
	property int speedValue: 0;

	function getDBusSpeedValue(value)
	{
		var returnValue;
		switch (value)
		{
			case 0:
				returnValue = 0;
			break;
			case 1:
				returnValue = 1;
			break;
			case 2:
				returnValue = 2;
			break;
			case 3:
				returnValue = 4;
			break;
			case 4:
				returnValue = 8;
			break;
			case 5:
				returnValue = 16;
			break;
			case 6:
				returnValue = 32;
			break;
			case 7:
				returnValue = 64;
			break;
			default:
				returnValue = 0;
			break;
		}	
		return	returnValue;
	}

	function update()
	{
	    var res=Genivi.mapmatch_message_get(dbusIf,"GetSimulationStatus",[]);
		// FIXME: Result is first arg instead of last?
		if (res[0] == 'uint16') 
		{
			console.log(res[1]);
			console.log(Genivi.NAVIGATIONCORE_SIMULATION_STATUS_RUNNING);
	        if (res[1] != Genivi.NAVIGATIONCORE_SIMULATION_STATUS_NO_SIMULATION)
	        {
				on_off.setState("ON");
				if (res[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_PAUSED) 
				{
					simu_mode.setState("PAUSE");
				} 
				else 
				{
					if (res[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_RUNNING) 
					{
						simu_mode.setState("PLAY");
					}
				}
	        }
			else
	        {
				on_off.setState("OFF");
				simu_mode.setState("FREE");
	        }
		} else {
            console.log("Unexpected result from GetSimulationStatus:");
			Genivi.dump("",res);
		}

        var res=Genivi.mapmatch_message_get(dbusIf,"GetSimulationSpeed",[]);
		if (res[0] == "uint8") {
			if (res[1] == 0) {
				speed.text="0";
				speedValue=0;
			}
			if (res[1] == 1) {
				speed.text="1/4";
				speedValue=1;
			}
			if (res[1] == 2) {
				speed.text="1/2";
				speedValue=2;
			}
			if (res[1] == 4) {
				speed.text="1";
				speedValue=3;
			}
			if (res[1] == 8) {
				speed.text="2";
				speedValue=4;
			}
			if (res[1] == 16) {
				speed.text="4";
				speedValue=5;
			}
			if (res[1] == 32) {
				speed.text="8";
				speedValue=6;
			}
			if (res[1] == 64) {
				speed.text="16";
				speedValue=7;
			}
		} else {
			console.log("Unexpected result from GetSimulationSpeed:");
			Genivi.dump("",res);
		}
	}

	HMIBgImage {
		id: content
        image:"navigation-settings-menu-background";
//Important notice: x,y coordinates from the left/top origin, so take in account the header of 26 pixels high
		anchors { fill: parent; topMargin: parent.headlineHeight}

		Text {
                height:menu.hspc
				x:38; y:50;
                font.pixelSize: 25;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: Genivi.gettext("Simulation")
             }
		Text {
                height:menu.hspc
				x:82; y:178;
                font.pixelSize: 25;
                style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true
				text: Genivi.gettext("Speed")
             }
		Text {
				id:speed
                height:menu.hspc
				x:102; y:112;
                font.pixelSize: 32;
                style: Text.Sunken; color: "black"; styleColor: "black"; smooth: true
				text: ""
             }

		StdButton {source:"Core/images/speed-down.png"; x:40; y:108; width:37; height:42; id:speed_down; explode:false; disabled:false; next:back; prev:back;
			onClicked:
			{
				if (speedValue > 0)
					speedValue = speedValue-1;
				Genivi.mapmatch_message(dbusIf,"SetSimulationSpeed",["uint8",getDBusSpeedValue(speedValue)]);
				update();
			}
		}
		StdButton {source:"Core/images/speed-up.png"; x:160; y:108; width:37; height:42; id:speed_up; explode:false; disabled:false; next:back; prev:back;
			onClicked:
			{
				if (speedValue < 7)
					speedValue = speedValue+1;
				Genivi.mapmatch_message(dbusIf,"SetSimulationSpeed",["uint8",getDBusSpeedValue(speedValue)]);
				update();
			}
		}

		Text {
                height:menu.hspc
				x:330; y:178;
                font.pixelSize: 25;
                style: Text.Sunken; color: "white"; styleColor: "white"; smooth: true
				text: Genivi.gettext("Mode")
             }

		StdButton { x:260; y:102; width:100; height:60; id:on_off; next:back; prev:back; explode:false; disabled:false; 
			property int status: 0;
			function setState(name)
			{
				if (name=="ON")
				{
					status=1;
					source="Core/images/simulation-off.png";
				}
				else
				{
					status=0;
					source="Core/images/simulation-on.png";
				}
            }
			onClicked:
			{
				switch (status) 
				{
					case 0: //start the simulation
						Genivi.mapmatch_message(dbusIf,"SetSimulationMode",["boolean",1]);
						Genivi.mapmatch_message(dbusIf,"StartSimulation",[]);
					break;
					case 1: //stop the simulation
						Genivi.mapmatch_message(dbusIf,"SetSimulationMode",["boolean",0]);
                    break;
					default:
					break;
				}
                update();
			}
		}
		StdButton { x:400; y:102; width:100; height:60; id:simu_mode; next:back; prev:back; explode:false; disabled:false; 
			property int status: 0;
			function setState(name)
			{
				if (name=="FREE")
				{
					status=0;
					source="Core/images/play.png";
					disabled=true;
				}
				else
				{
					if (name=="PLAY")
					{
						status=1;
						source="Core/images/play.png";
						enabled=true;
					}
					else
					{
						if (name=="PAUSE")
						{
							status=2;
							source="Core/images/pause.png";
							enabled=true;
						}
					}
				}
            }
			onClicked:
			{
				switch (status) 
				{
					case 1: //pause
						//pause to resume
		        		Genivi.mapmatch_message(dbusIf,"StartSimulation",[]);
                    break;
					case 2: //resume
						//resume to pause
            			Genivi.mapmatch_message(dbusIf,"PauseSimulation",[]);
                    break;
					default:
					break;
				}
                update();
            }
		}

		StdButton { textColor:"black"; pixelSize:38 ; source:"Core/images/preferences.png"; x:20; y:374; width:260; height:60; id:preferences; text: Genivi.gettext("Preference"); disabled:false; next:language; prev:back; page:"NavigationSettingsPreferences"}

		StdButton { textColor:"black"; pixelSize:38 ; source:"Core/images/language-and-unit.png"; x:310; y:374; width:260; height:60; id:language; text: Genivi.gettext("LanguageAndUnits"); disabled:false; next:back; prev:preferences; page:"NavigationSettingsLanguageAndUnits"}

		StdButton { textColor:"black"; pixelSize:38 ; source:"Core/images/back.png"; x:600; y:374; width:180; height:60; id:back; text: Genivi.gettext("Back"); disabled:false; next:preferences; prev:language; page:"MainMenu"}
		Component.onCompleted: {
			update();
		}
	}
}
