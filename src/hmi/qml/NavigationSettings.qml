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
import "Core/style-sheets/style-constants.js" as Constants;
import "Core/style-sheets/navigation-settings-menu-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0

HMIMenu {
	id: menu
    property Item simulationStatusChangedSignal;
    property Item simulationSpeedChangedSignal;
    next: back
        prev: back

    DBusIf {
		id:dbusIf;
	}

    property int speedValueSent: 0;

    function simulationSpeedChanged(args)
    {
        if (args[0] == 'uint8')
        {
            if (args[1] == 0) {
                speedValue.text="0";
                speedValueSent=0;
            }
            if (args[1] == 1) {
                speedValue.text="1/4";
                speedValueSent=1;
            }
            if (args[1] == 2) {
                speedValue.text="1/2";
                speedValueSent=2;
            }
            if (args[1] == 4) {
                speedValue.text="1";
                speedValueSent=3;
            }
            if (args[1] == 8) {
                speedValue.text="2";
                speedValueSent=4;
            }
            if (args[1] == 16) {
                speedValue.text="4";
                speedValueSent=5;
            }
            if (args[1] == 32) {
                speedValue.text="8";
                speedValueSent=6;
            }
            if (args[1] == 64) {
                speedValue.text="16";
                speedValueSent=7;
            }
        }
        else
        {
            console.log("Unexpected result from SimulationSpeedChanged:");
            Genivi.dump("",args);
        }

    }

    function simulationStatusChanged(args)
    {
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
            console.log("Unexpected result from SimulationStatusChanged:");
            Genivi.dump("",args);
        }

    }

    function connectSignals()
    {
        simulationStatusChangedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.MapMatchedPosition","SimulationStatusChanged",menu,"simulationStatusChanged");
        simulationSpeedChangedSignal=dbusIf.connect("","/org/genivi/navigationcore","org.genivi.navigationcore.MapMatchedPosition","SimulationSpeedChanged",menu,"simulationSpeedChanged");
    }

    function disconnectSignals()
    {
        simulationStatusChangedSignal.destroy();
        simulationSpeedChangedSignal.destroy();
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

    function updateSimulation()
	{
	    var res=Genivi.mapmatch_message_get(dbusIf,"GetSimulationStatus",[]);
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
        image:StyleSheet.navigation_settings_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

		Text {
            x:StyleSheet.simulationTitle[Constants.X]; y:StyleSheet.simulationTitle[Constants.Y]; width:StyleSheet.simulationTitle[Constants.WIDTH]; height:StyleSheet.simulationTitle[Constants.HEIGHT];color:StyleSheet.simulationTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.simulationTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.simulationTitle[Constants.PIXELSIZE];
            id:simulationTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Simulation")
             }

        Text {
            x:StyleSheet.speedTitle[Constants.X]; y:StyleSheet.speedTitle[Constants.Y]; width:StyleSheet.speedTitle[Constants.WIDTH]; height:StyleSheet.speedTitle[Constants.HEIGHT];color:StyleSheet.speedTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.speedTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.speedTitle[Constants.PIXELSIZE];
            id:speedTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Speed")
             }

        Text {
            x:StyleSheet.speedValue[Constants.X]; y:StyleSheet.speedValue[Constants.Y]; width:StyleSheet.speedValue[Constants.WIDTH]; height:StyleSheet.speedValue[Constants.HEIGHT];color:StyleSheet.speedValue[Constants.TEXTCOLOR];styleColor:StyleSheet.speedValue[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.speedValue[Constants.PIXELSIZE];
            id:speedValue
            style: Text.Sunken;
            smooth: true
            text: ""
             }

        StdButton {
            source:StyleSheet.speed_down[Constants.SOURCE]; x:StyleSheet.speed_down[Constants.X]; y:StyleSheet.speed_down[Constants.Y]; width:StyleSheet.speed_down[Constants.WIDTH]; height:StyleSheet.speed_down[Constants.HEIGHT];
            id:speed_down; explode:false; disabled:false; next:back; prev:back;
			onClicked:
			{
                if (speedValueSent > 0)
                {
                    speedValueSent = speedValueSent-1;
                }
                Genivi.mapmatch_message(dbusIf,"SetSimulationSpeed",["uint8",getDBusSpeedValue(speedValueSent)]);
			}
		}

        StdButton {
            source:StyleSheet.speed_up[Constants.SOURCE]; x:StyleSheet.speed_up[Constants.X]; y:StyleSheet.speed_up[Constants.Y]; width:StyleSheet.speed_up[Constants.WIDTH]; height:StyleSheet.speed_up[Constants.HEIGHT];
            id:speed_up; explode:false; disabled:false; next:back; prev:back;
			onClicked:
			{
                if (speedValueSent < 7)
                {
                    speedValueSent = speedValueSent+1;
                }
                Genivi.mapmatch_message(dbusIf,"SetSimulationSpeed",["uint8",getDBusSpeedValue(speedValueSent)]);
			}
		}

		Text {
            x:StyleSheet.modeTitle[Constants.X]; y:StyleSheet.modeTitle[Constants.Y]; width:StyleSheet.modeTitle[Constants.WIDTH]; height:StyleSheet.modeTitle[Constants.HEIGHT];color:StyleSheet.modeTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.modeTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.modeTitle[Constants.PIXELSIZE];
            id:modeTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Mode")
             }

        Text {
            x:StyleSheet.onmapviewTitle[Constants.X]; y:StyleSheet.onmapviewTitle[Constants.Y]; width:StyleSheet.onmapviewTitle[Constants.WIDTH]; height:StyleSheet.onmapviewTitle[Constants.HEIGHT];color:StyleSheet.onmapviewTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.onmapviewTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.onmapviewTitle[Constants.PIXELSIZE];
            id:onmapviewTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("OnMapView")
             }

        StdButton {
            x:StyleSheet.simulation_on[Constants.X]; y:StyleSheet.simulation_on[Constants.Y]; width:StyleSheet.simulation_on[Constants.WIDTH]; height:StyleSheet.simulation_on[Constants.HEIGHT];
            id:on_off; next:back; prev:back; explode:false; disabled:false;
			property int status: 0;
			function setState(name)
			{
				if (name=="ON")
				{
					status=1;
                    source=StyleSheet.simulation_off[Constants.SOURCE];
				}
				else
				{
					status=0;
                    source=StyleSheet.simulation_on[Constants.SOURCE];
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

        StdButton {
            x:StyleSheet.play[Constants.X]; y:StyleSheet.play[Constants.Y]; width:StyleSheet.play[Constants.WIDTH]; height:StyleSheet.play[Constants.HEIGHT];
            id:simu_mode; next:back; prev:back; explode:false; disabled:false;
			property int status: 0;
			function setState(name)
			{
				if (name=="FREE")
				{
					status=0;
                    source=StyleSheet.play[Constants.SOURCE];
					disabled=true;
				}
				else
				{
					if (name=="PLAY")
					{
						status=1;
                        source=StyleSheet.pause[Constants.SOURCE];
						enabled=true;
                        disabled=false;
					}
					else
					{
						if (name=="PAUSE")
						{
							status=2;
                            source=StyleSheet.play[Constants.SOURCE];
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

        StdButton {
            source:StyleSheet.preferences[Constants.SOURCE]; x:StyleSheet.preferences[Constants.X]; y:StyleSheet.preferences[Constants.Y]; width:StyleSheet.preferences[Constants.WIDTH]; height:StyleSheet.preferences[Constants.HEIGHT];textColor:StyleSheet.preferencesText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.preferencesText[Constants.PIXELSIZE];
            id:preferences; text: Genivi.gettext("Preference"); disabled:false; next:languageAndUnit; prev:back; page:"NavigationSettingsPreferences"}

        StdButton {
            source:StyleSheet.languageAndUnit[Constants.SOURCE]; x:StyleSheet.languageAndUnit[Constants.X]; y:StyleSheet.languageAndUnit[Constants.Y]; width:StyleSheet.languageAndUnit[Constants.WIDTH]; height:StyleSheet.languageAndUnit[Constants.HEIGHT];textColor:StyleSheet.languageAndUnitText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.languageAndUnitText[Constants.PIXELSIZE];
            id:languageAndUnit; text: Genivi.gettext("LanguageAndUnits"); disabled:false; next:back; prev:preferences; page:"NavigationSettingsLanguageAndUnits"}

        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); disabled:false; next:onmapview_enable; prev:languageAndUnit;
            onClicked:{leave(); pageOpen("MainMenu");}
        }

        StdButton {
            x:StyleSheet.onmapview_enable[Constants.X]; y:StyleSheet.onmapview_enable[Constants.Y]; width:StyleSheet.onmapview_enable[Constants.WIDTH]; height:StyleSheet.onmapview_enable[Constants.HEIGHT];
            id:onmapview_enable; next:back; prev:preferences; explode:false; disabled:false;
            source:
            {
                if (Genivi.simulationPanelOnMapview==true)
                {
                    source=StyleSheet.onmapview_enable[Constants.SOURCE];
                }
                else
                {
                    source=StyleSheet.onmapview_disable[Constants.SOURCE];
                }
            }

            function setState(name)
            {
                if (name=="ENABLE")
                {
                    source=StyleSheet.onmapview_enable[Constants.SOURCE];
                }
                else
                {
                    source=StyleSheet.onmapview_disable[Constants.SOURCE];
                }
            }
            onClicked:
            {
                if (Genivi.simulationPanelOnMapview==true)
                { //hide the panel
                    Genivi.simulationPanelOnMapview=false;
                    onmapview_enable.setState("DISABLE");
                }
                else
                { //show the panel
                    Genivi.simulationPanelOnMapview=true;
                    onmapview_enable.setState("ENABLE");
                }
            }
        }

	}

    Component.onCompleted: {
        connectSignals();
        updateSimulation();
    }
}
