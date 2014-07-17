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
import QtQuick 2.1 
import "Core"
import "Core/genivi.js" as Genivi;
import "Core/style-sheets/navigation-settings-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    headlineFg: "grey"
    headlineBg: "blue"
    text: Genivi.gettext("NavigationSettings")
    property Item simulationStatusChangedSignal;
    next: back
        prev: back

    DBusIf {
		id:dbusIf;
	}

    property int speedValueSent: 0;

    function simulationStatusChanged(args)
    {
        console.log("SimulationStatusChanged");
        Genivi.dump("",args);
        if (args[0] == 'uint16')
        {
            if (args[1] != Genivi.NAVIGATIONCORE_SIMULATION_STATUS_NO_SIMULATION)
            {
                on_off.setState("ON");
                if (args[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_PAUSED || args[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_FIXED_POSITION)
                {
                    simu_mode.setState("PAUSE");
                }
                else
                {
                    if (args[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_RUNNING)
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
            Genivi.dump("",args);
        }

    }

    function connectSignals()
    {
        simulationStatusChangedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.MapMatchedPosition","SimulationStatusChanged",menu,"simulationStatusChanged");
    }

    function disconnectSignals()
    {
        simulationStatusChangedSignal.destroy();
    }


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
        console.log("GetSimulationStatus");
        Genivi.dump("",res);
        if (res[0] == 'uint16')
		{
            if (res[1] != Genivi.NAVIGATIONCORE_SIMULATION_STATUS_NO_SIMULATION)
	        {
				on_off.setState("ON");
                if (res[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_PAUSED || res[1] == Genivi.NAVIGATIONCORE_SIMULATION_STATUS_FIXED_POSITION)
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

        var res1=Genivi.mapmatch_message_get(dbusIf,"GetSimulationSpeed",[]);
        if (res1[0] == "uint8") {
            if (res1[1] == 0) {
                speedValue.text="0";
                speedValueSent=0;
			}
            if (res1[1] == 1) {
                speedValue.text="1/4";
                speedValueSent=1;
			}
            if (res1[1] == 2) {
                speedValue.text="1/2";
                speedValueSent=2;
			}
            if (res1[1] == 4) {
                speedValue.text="1";
                speedValueSent=3;
			}
            if (res1[1] == 8) {
                speedValue.text="2";
                speedValueSent=4;
			}
            if (res1[1] == 16) {
                speedValue.text="4";
                speedValueSent=5;
			}
            if (res1[1] == 32) {
                speedValue.text="8";
                speedValueSent=6;
			}
            if (res1[1] == 64) {
                speedValue.text="16";
                speedValueSent=7;
			}
		} else {
			console.log("Unexpected result from GetSimulationSpeed:");
            Genivi.dump("",res1);
		}
	}

    function leave()
    {
        disconnectSignals();
    }

	HMIBgImage {
		id: content
        image:StyleSheet.navigation_settings_background[StyleSheet.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

		Text {
            x:StyleSheet.simulationTitle[StyleSheet.X]; y:StyleSheet.simulationTitle[StyleSheet.Y]; width:StyleSheet.simulationTitle[StyleSheet.WIDTH]; height:StyleSheet.simulationTitle[StyleSheet.HEIGHT];color:StyleSheet.simulationTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.simulationTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.simulationTitle[StyleSheet.PIXELSIZE];
            id:simulationTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Simulation")
             }
		Text {
            x:StyleSheet.speedTitle[StyleSheet.X]; y:StyleSheet.speedTitle[StyleSheet.Y]; width:StyleSheet.speedTitle[StyleSheet.WIDTH]; height:StyleSheet.speedTitle[StyleSheet.HEIGHT];color:StyleSheet.speedTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.speedTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.speedTitle[StyleSheet.PIXELSIZE];
            id:speedTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Speed")
             }
		Text {
            x:StyleSheet.speedValue[StyleSheet.X]; y:StyleSheet.speedValue[StyleSheet.Y]; width:StyleSheet.speedValue[StyleSheet.WIDTH]; height:StyleSheet.speedValue[StyleSheet.HEIGHT];color:StyleSheet.speedValue[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.speedValue[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.speedValue[StyleSheet.PIXELSIZE];
            id:speedValue
            style: Text.Sunken;
            smooth: true
            text: ""
             }

        StdButton {source:StyleSheet.speed_down[StyleSheet.SOURCE]; x:StyleSheet.speed_down[StyleSheet.X]; y:StyleSheet.speed_down[StyleSheet.Y]; width:StyleSheet.speed_down[StyleSheet.WIDTH]; height:StyleSheet.speed_down[StyleSheet.HEIGHT];
            id:speed_down; explode:false; disabled:false; next:back; prev:back;
			onClicked:
			{
                if (speedValueSent > 0)
                    speedValueSent = speedValueSent-1;
                Genivi.mapmatch_message(dbusIf,"SetSimulationSpeed",["uint8",getDBusSpeedValue(speedValueSent)]);
				update();
			}
		}
        StdButton {source:StyleSheet.speed_up[StyleSheet.SOURCE]; x:StyleSheet.speed_up[StyleSheet.X]; y:StyleSheet.speed_up[StyleSheet.Y]; width:StyleSheet.speed_up[StyleSheet.WIDTH]; height:StyleSheet.speed_up[StyleSheet.HEIGHT];
            id:speed_up; explode:false; disabled:false; next:back; prev:back;
			onClicked:
			{
                if (speedValueSent < 7)
                    speedValueSent = speedValueSent+1;
                Genivi.mapmatch_message(dbusIf,"SetSimulationSpeed",["uint8",getDBusSpeedValue(speedValueSent)]);
				update();
			}
		}

		Text {
            x:StyleSheet.modeTitle[StyleSheet.X]; y:StyleSheet.modeTitle[StyleSheet.Y]; width:StyleSheet.modeTitle[StyleSheet.WIDTH]; height:StyleSheet.modeTitle[StyleSheet.HEIGHT];color:StyleSheet.modeTitle[StyleSheet.TEXTCOLOR];styleColor:StyleSheet.modeTitle[StyleSheet.STYLECOLOR]; font.pixelSize:StyleSheet.modeTitle[StyleSheet.PIXELSIZE];
            id:modeTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Mode")
             }

        StdButton { x:StyleSheet.simulation_on[StyleSheet.X]; y:StyleSheet.simulation_on[StyleSheet.Y]; width:StyleSheet.simulation_on[StyleSheet.WIDTH]; height:StyleSheet.simulation_on[StyleSheet.HEIGHT];
            id:on_off; next:back; prev:back; explode:false; disabled:false;
			property int status: 0;
			function setState(name)
			{
				if (name=="ON")
				{
					status=1;
                    source=StyleSheet.simulation_off[StyleSheet.SOURCE];
				}
				else
				{
					status=0;
                    source=StyleSheet.simulation_on[StyleSheet.SOURCE];
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
			}
		}
        StdButton { x:StyleSheet.play[StyleSheet.X]; y:StyleSheet.play[StyleSheet.Y]; width:StyleSheet.play[StyleSheet.WIDTH]; height:StyleSheet.play[StyleSheet.HEIGHT];
            id:simu_mode; next:back; prev:back; explode:false; disabled:false;
			property int status: 0;
			function setState(name)
			{
				if (name=="FREE")
				{
					status=0;
                    source=StyleSheet.play[StyleSheet.SOURCE];
					disabled=true;
				}
				else
				{
					if (name=="PLAY")
					{
						status=1;
                        source=StyleSheet.pause[StyleSheet.SOURCE];
						enabled=true;
                        disabled=false;
					}
					else
					{
						if (name=="PAUSE")
						{
							status=2;
                            source=StyleSheet.play[StyleSheet.SOURCE];
							enabled=true;
                            disabled=false;
						}
					}
				}
            }
			onClicked:
			{
				switch (status) 
				{
                    case 2: //pause
						//pause to resume
		        		Genivi.mapmatch_message(dbusIf,"StartSimulation",[]);
                    break;
                    case 1: //play
                        //play to pause
            			Genivi.mapmatch_message(dbusIf,"PauseSimulation",[]);
                    break;
					default:
					break;
				}
            }
		}

        StdButton { source:StyleSheet.preferences[StyleSheet.SOURCE]; x:StyleSheet.preferences[StyleSheet.X]; y:StyleSheet.preferences[StyleSheet.Y]; width:StyleSheet.preferences[StyleSheet.WIDTH]; height:StyleSheet.preferences[StyleSheet.HEIGHT];textColor:StyleSheet.preferencesText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.preferencesText[StyleSheet.PIXELSIZE];
            id:preferences; text: Genivi.gettext("Preference"); disabled:false; next:languageAndUnit; prev:back; page:"NavigationSettingsPreferences"}

        StdButton {source:StyleSheet.languageAndUnit[StyleSheet.SOURCE]; x:StyleSheet.languageAndUnit[StyleSheet.X]; y:StyleSheet.languageAndUnit[StyleSheet.Y]; width:StyleSheet.languageAndUnit[StyleSheet.WIDTH]; height:StyleSheet.languageAndUnit[StyleSheet.HEIGHT];textColor:StyleSheet.languageAndUnitText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.languageAndUnitText[StyleSheet.PIXELSIZE];
            id:languageAndUnit; text: Genivi.gettext("LanguageAndUnits"); disabled:false; next:back; prev:preferences; page:"NavigationSettingsLanguageAndUnits"}

        StdButton { source:StyleSheet.back[StyleSheet.SOURCE]; x:StyleSheet.back[StyleSheet.X]; y:StyleSheet.back[StyleSheet.Y]; width:StyleSheet.back[StyleSheet.WIDTH]; height:StyleSheet.back[StyleSheet.HEIGHT];textColor:StyleSheet.backText[StyleSheet.TEXTCOLOR]; pixelSize:StyleSheet.backText[StyleSheet.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); disabled:false; next:preferences; prev:languageAndUnit;
            onClicked:{leave(); pageOpen("MainMenu");}
        }

	}

    Component.onCompleted: {
        connectSignals();
        update();
    }
}
