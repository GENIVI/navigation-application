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
import "Core/style-sheets/NavigationAppSettings-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0
import lbs.plugin.preference 1.0

NavigationAppHMIMenu {
	id: menu
    property string pagefile:"NavigationAppSettings"
    next: back
    prev: back

    //------------------------------------------//
    // Management of the DBus exchanges
    //------------------------------------------//
    DBusIf {
		id:dbusIf;
	}

    property Item configurationChangedSignal;
    function configurationChanged(args)
    { //to be improved !
        Genivi.hookSignal("configurationChanged");
        for (var i=0; i < args[1].length;i+=2) {
            switch (args[1][i+1]) {
            case Genivi.NAVIGATIONCORE_LOCALE:
                update();
                break;
            case Genivi.NAVIGATIONCORE_UNITS_OF_MEASUREMENT:
                update();
                break;
            }
        }
    }

    function connectSignals()
    {
        configurationChangedSignal=Genivi.connect_configurationChangedSignal(dbusIf,menu);
    }

    function disconnectSignals()
    {
        configurationChangedSignal.destroy();
    }

    //------------------------------------------//
    // Management of the language and units
    //------------------------------------------//

    function updateLanguageAndUnits()
    {
        var available_nav=Genivi.navigationcore_configuration_GetSupportedLocales(dbusIf);
        var available_map=Genivi.mapviewer_configuration_GetSupportedLocales(dbusIf);
        var current_nav=Genivi.navigationcore_configuration_GetLocale(dbusIf);
        var current_map=Genivi.mapviewer_configuration_GetLocale(dbusIf);
        var current_lang_nav;
        var current_lang_map;
        var lang_nav=[];
        var lang_map=[];

        current_lang_nav=current_nav[1] + "_" + current_nav[3];
        current_lang_map=current_map[1] + "_" + current_map[3];

        for (var i = 0 ; i < available_nav[1].length ; i+=2) {
            lang_nav[available_nav[1][i+1][1]+"_"+available_nav[1][i+1][3]]=true;
        }

        for (var i = 0 ; i < available_map[1].length ; i+=2) {
            lang_map[available_map[1][i+1][1]+"_"+available_map[1][i+1][3]]=true;
        }

        // only the locales for nav are used
        for (var i = 0 ; i < content.children.length ; i++) {
            var name=content.children[i].objectName;
            if (name) {
                content.children[i].visible=true;
                if (name == current_lang_nav) {
                    content.children[i].disabled=true;
                }
                else {
                    content.children[i].disabled=false;
                }
            }
        }

        Genivi.setlang(current_lang_nav);

        var units1,units2;
        var res=Genivi.navigationcore_configuration_GetUnitsOfMeasurement(dbusIf);

        if (res[1][1] == Genivi.NAVIGATIONCORE_LENGTH) {
            units1=res[1][3];
        }
        var res1=Genivi.mapviewer_configuration_GetUnitsOfMeasurement(dbusIf);
        if (res1[1][1] == Genivi.MAPVIEWER_LENGTH) {
            units2=res1[1][3];
        }
        unit_km.disabled=false;
        unit_mile.disabled=false;
        if (units1==Genivi.NAVIGATIONCORE_KM) unit_km.disabled=true;
        if (units1==Genivi.NAVIGATIONCORE_MILE) unit_mile.disabled=true;
    }

    function setLocale(language, country, script)
    {
        Genivi.navigationcore_configuration_SetLocale(dbusIf,language,country,script);
        Genivi.mapviewer_configuration_SetLocale(dbusIf,language,country,script);
        Genivi.setlang(language + "_" + country);
        pageOpen(menu.pagefile); //reload page because of texts...
    }

    function setUnitsLength(units1,units2)
    {
        Genivi.navigationcore_configuration_SetUnitsOfMeasurementLength(dbusIf,units1);
        Genivi.mapviewer_configuration_SetUnitsOfMeasurementLength(dbusIf,units2);
        updateLanguageAndUnits();
    }

    //------------------------------------------//
    // Management of the preferences
    //------------------------------------------//
    // please note that the preferences are hard coded, limited to three couples:
    //    (NAVIGATIONCORE_AVOID,NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)
    //    (NAVIGATIONCORE_AVOID,NAVIGATIONCORE_TOLL_ROADS)
    //    (NAVIGATIONCORE_AVOID,NAVIGATIONCORE_FERRY)

    Preference {
        source: 0
        mode: 0
    }

    function updatePreferences()
    {
        Genivi.routing_SetRoutePreferences(dbusIf,""); //preferences applied to all countries
        var active=Genivi.routing_GetRoutePreferences(dbusIf,"");

        var roadPreferenceList;
        var conditionPreferenceList;
        roadPreferenceList=active[1];
        conditionPreferenceList=active[3];
        var roadPreferenceMode,roadPreferenceSource;
        var conditionPreferenceMode,conditionPreferenceSource;

        for(var i=0; i<roadPreferenceList.length; i+=2)
        {
            roadPreferenceMode=roadPreferenceList[i+1][1];
            roadPreferenceSource=roadPreferenceList[i+1][3];
            Genivi.roadPreferenceList[roadPreferenceSource]=roadPreferenceMode;

            if(roadPreferenceSource == Genivi.NAVIGATIONCORE_FERRY)
            {
                if(roadPreferenceMode == Genivi.NAVIGATIONCORE_AVOID)
                {
                    ferries_yes.disabled=false;
                    ferries_no.disabled=true;
                }
                else
                {
                    ferries_yes.disabled=true;
                    ferries_no.disabled=false;
                }
            }
            else
            {
                if(roadPreferenceSource == Genivi.NAVIGATIONCORE_TOLL_ROADS)
                {
                    if(roadPreferenceMode == Genivi.NAVIGATIONCORE_AVOID)
                    {
                        toll_roads_yes.disabled=false;
                        toll_roads_no.disabled=true;
                    }
                    else
                    {
                        toll_roads_yes.disabled=true;
                        toll_roads_no.disabled=false;
                    }
                }
                else
                {
                    if(roadPreferenceSource == Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)
                    {
                        if(roadPreferenceMode == Genivi.NAVIGATIONCORE_AVOID)
                        {
                            motorways_yes.disabled=false;
                            motorways_no.disabled=true;
                        }
                        else
                        {
                            motorways_yes.disabled=true;
                            motorways_no.disabled=false;
                        }
                    }
                }
            }
        }
    }

    function use(preferenceSource)
    {
        Genivi.roadPreferenceList[preferenceSource]=Genivi.NAVIGATIONCORE_USE;
        updatePreferences();
    }

    function avoid(preferenceSource)
    {
        Genivi.roadPreferenceList[preferenceSource]=Genivi.NAVIGATIONCORE_AVOID;
        updatePreferences();
    }

    //------------------------------------------//
    // Menu elements
    //------------------------------------------//
    NavigationAppHMIBgImage {
		id: content
        image:StyleSheet.navigation_app_settings_background[Constants.SOURCE];
        anchors { fill: parent; topMargin: parent.headlineHeight}

        Text {
            x:StyleSheet.languagesTitle[Constants.X]; y:StyleSheet.languagesTitle[Constants.Y]; width:StyleSheet.languagesTitle[Constants.WIDTH]; height:StyleSheet.languagesTitle[Constants.HEIGHT];color:StyleSheet.languagesTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.languagesTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.languagesTitle[Constants.PIXELSIZE];
            id:languagesTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Language")
             }
        StdButton { objectName:"fra_FRA";
            source:StyleSheet.french_flag[Constants.SOURCE]; x:StyleSheet.french_flag[Constants.X]; y:StyleSheet.french_flag[Constants.Y]; width:StyleSheet.french_flag[Constants.WIDTH]; height:StyleSheet.french_flag[Constants.HEIGHT];
            id:fra_FRA; disabled:false; next:deu_DEU; prev:back;  onClicked: {setLocale("fra","FRA","Latn");}}
        StdButton { objectName:"deu_DEU";
            source:StyleSheet.german_flag[Constants.SOURCE]; x:StyleSheet.german_flag[Constants.X]; y:StyleSheet.german_flag[Constants.Y]; width:StyleSheet.german_flag[Constants.WIDTH]; height:StyleSheet.german_flag[Constants.HEIGHT];
             id:deu_DEU; disabled:false; next:eng_USA; prev:fra_FRA;  onClicked: {setLocale("deu","DEU","Latn");}}
        StdButton { objectName:"eng_USA";
            source:StyleSheet.usa_flag[Constants.SOURCE]; x:StyleSheet.usa_flag[Constants.X]; y:StyleSheet.usa_flag[Constants.Y]; width:StyleSheet.usa_flag[Constants.WIDTH]; height:StyleSheet.usa_flag[Constants.HEIGHT];
            id:eng_USA; disabled:false; next:jpn_JPN; prev:deu_DEU;  onClicked: {setLocale("eng","USA","Latn");}}
        StdButton { objectName:"jpn_JPN";
            source:StyleSheet.japanese_flag[Constants.SOURCE]; x:StyleSheet.japanese_flag[Constants.X]; y:StyleSheet.japanese_flag[Constants.Y]; width:StyleSheet.japanese_flag[Constants.WIDTH]; height:StyleSheet.japanese_flag[Constants.HEIGHT];
            id:jpn_JPN; disabled:false; next:back; prev:eng_USA;  onClicked: {setLocale("jpn","JPN","Hrkt");}}

        Text {
            x:StyleSheet.unitsTitle[Constants.X]; y:StyleSheet.unitsTitle[Constants.Y]; width:StyleSheet.unitsTitle[Constants.WIDTH]; height:StyleSheet.unitsTitle[Constants.HEIGHT];color:StyleSheet.unitsTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.unitsTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.unitsTitle[Constants.PIXELSIZE];
            id:unitsTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Units")
             }
        StdButton { source:StyleSheet.unit_km[Constants.SOURCE]; x:StyleSheet.unit_km[Constants.X]; y:StyleSheet.unit_km[Constants.Y]; width:StyleSheet.unit_km[Constants.WIDTH]; height:StyleSheet.unit_km[Constants.HEIGHT];
            id:unit_km;  disabled:false; next:back; prev:back;
            onClicked: {
                setUnitsLength(Genivi.NAVIGATIONCORE_KM,Genivi.MAPVIEWER_KM);}
        }
        StdButton { source:StyleSheet.unit_mile[Constants.SOURCE]; x:StyleSheet.unit_mile[Constants.X]; y:StyleSheet.unit_mile[Constants.Y]; width:StyleSheet.unit_mile[Constants.WIDTH]; height:StyleSheet.unit_mile[Constants.HEIGHT];
            id:unit_mile;  disabled:false; next:back; prev:back;
            onClicked: {
                setUnitsLength(Genivi.NAVIGATIONCORE_MILE,Genivi.MAPVIEWER_MILE);}
        }

        Text {
            x:StyleSheet.costModelTitle[Constants.X]; y:StyleSheet.costModelTitle[Constants.Y]; width:StyleSheet.costModelTitle[Constants.WIDTH]; height:StyleSheet.costModelTitle[Constants.HEIGHT];color:StyleSheet.costModelTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.costModelTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.costModelTitle[Constants.PIXELSIZE];
            id:costModelTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("CostModel")
        }

        Text {
            x:StyleSheet.routingPreferencesTitle[Constants.X]; y:StyleSheet.routingPreferencesTitle[Constants.Y]; width:StyleSheet.routingPreferencesTitle[Constants.WIDTH]; height:StyleSheet.routingPreferencesTitle[Constants.HEIGHT];color:StyleSheet.routingPreferencesTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.routingPreferencesTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.routingPreferencesTitle[Constants.PIXELSIZE];
            id:routingPreferencesTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("RoutingPreferences")
        }

        Text {
            x:StyleSheet.ferriesText[Constants.X]; y:StyleSheet.ferriesText[Constants.Y]; width:StyleSheet.ferriesText[Constants.WIDTH]; height:StyleSheet.ferriesText[Constants.HEIGHT];color:StyleSheet.ferriesText[Constants.TEXTCOLOR];styleColor:StyleSheet.ferriesText[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.ferriesText[Constants.PIXELSIZE];
            id: ferriesText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Ferries")
        }
        StdButton { source:StyleSheet.allow_ferries[Constants.SOURCE]; x:StyleSheet.allow_ferries[Constants.X]; y:StyleSheet.allow_ferries[Constants.Y]; width:StyleSheet.allow_ferries[Constants.WIDTH]; height:StyleSheet.allow_ferries[Constants.HEIGHT];
            id:ferries_yes; next:back; prev:back;  onClicked:{use(Genivi.NAVIGATIONCORE_FERRY)}}
        StdButton { source:StyleSheet.avoid_ferries[Constants.SOURCE]; x:StyleSheet.avoid_ferries[Constants.X]; y:StyleSheet.avoid_ferries[Constants.Y]; width:StyleSheet.avoid_ferries[Constants.WIDTH]; height:StyleSheet.avoid_ferries[Constants.HEIGHT];
            id:ferries_no; next:back; prev:back;  onClicked:{avoid(Genivi.NAVIGATIONCORE_FERRY)}}

        Text {
            x:StyleSheet.tollRoadsText[Constants.X]; y:StyleSheet.tollRoadsText[Constants.Y]; width:StyleSheet.tollRoadsText[Constants.WIDTH]; height:StyleSheet.tollRoadsText[Constants.HEIGHT];color:StyleSheet.tollRoadsText[Constants.TEXTCOLOR];styleColor:StyleSheet.tollRoadsText[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.tollRoadsText[Constants.PIXELSIZE];
            id: tollRoadsText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("TollRoads")
        }
        StdButton { source:StyleSheet.allow_tollRoads[Constants.SOURCE]; x:StyleSheet.allow_tollRoads[Constants.X]; y:StyleSheet.allow_tollRoads[Constants.Y]; width:StyleSheet.allow_tollRoads[Constants.WIDTH]; height:StyleSheet.allow_tollRoads[Constants.HEIGHT];
            id:toll_roads_yes; next:back; prev:back;  onClicked:{use(Genivi.NAVIGATIONCORE_TOLL_ROADS)}}
        StdButton { source:StyleSheet.avoid_tollRoads[Constants.SOURCE]; x:StyleSheet.avoid_tollRoads[Constants.X]; y:StyleSheet.avoid_tollRoads[Constants.Y]; width:StyleSheet.avoid_tollRoads[Constants.WIDTH]; height:StyleSheet.avoid_tollRoads[Constants.HEIGHT];
            id:toll_roads_no;  next:back; prev:back;  onClicked:{avoid(Genivi.NAVIGATIONCORE_TOLL_ROADS)}}

        Text {
            x:StyleSheet.motorWaysText[Constants.X]; y:StyleSheet.motorWaysText[Constants.Y]; width:StyleSheet.motorWaysText[Constants.WIDTH]; height:StyleSheet.motorWaysText[Constants.HEIGHT];color:StyleSheet.motorWaysText[Constants.TEXTCOLOR];styleColor:StyleSheet.motorWaysText[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.motorWaysText[Constants.PIXELSIZE];
            id:motorWaysText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("MotorWays")
        }
        StdButton { source:StyleSheet.allow_motorways[Constants.SOURCE]; x:StyleSheet.allow_motorways[Constants.X]; y:StyleSheet.allow_motorways[Constants.Y]; width:StyleSheet.allow_motorways[Constants.WIDTH]; height:StyleSheet.allow_motorways[Constants.HEIGHT];
            id:motorways_yes; next:back; prev:back;  onClicked:{use(Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}
        StdButton { source:StyleSheet.avoid_motorways[Constants.SOURCE]; x:StyleSheet.avoid_motorways[Constants.X]; y:StyleSheet.avoid_motorways[Constants.Y]; width:StyleSheet.avoid_motorways[Constants.WIDTH]; height:StyleSheet.avoid_motorways[Constants.HEIGHT];
            id:motorways_no;  next:back; prev:back;  onClicked:{avoid(Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}

		Text {
            x:StyleSheet.simulationTitle[Constants.X]; y:StyleSheet.simulationTitle[Constants.Y]; width:StyleSheet.simulationTitle[Constants.WIDTH]; height:StyleSheet.simulationTitle[Constants.HEIGHT];color:StyleSheet.simulationTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.simulationTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.simulationTitle[Constants.PIXELSIZE];
            id:simulationTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Simulation")
             }
        StdButton {
            x:StyleSheet.simu_mode_enable[Constants.X]; y:StyleSheet.simu_mode_enable[Constants.Y]; width:StyleSheet.simu_mode_enable[Constants.WIDTH]; height:StyleSheet.simu_mode_enable[Constants.HEIGHT];
            id:simu_mode; next:back; prev:back;  disabled:false;
            source:
            {
                if (Genivi.simulationMode==true)
                {
                    source=StyleSheet.simu_mode_enable[Constants.SOURCE];
                }
                else
                {
                    source=StyleSheet.simu_mode_disable[Constants.SOURCE];
                }
            }

            function setState(name)
            {
                if (name=="ENABLE")
                {
                    source=StyleSheet.simu_mode_enable[Constants.SOURCE];
                }
                else
                {
                    source=StyleSheet.simu_mode_disable[Constants.SOURCE];
                }
            }
            onClicked:
            {
                if (Genivi.simulationMode==true)
                {
                    Genivi.simulationMode=false;
                    simu_mode.setState("DISABLE");
                }
                else
                {
                    Genivi.simulationMode=true;
                    simu_mode.setState("ENABLE");
                }
            }
        }

        Text {
            x:StyleSheet.showroomTitle[Constants.X]; y:StyleSheet.showroomTitle[Constants.Y]; width:StyleSheet.showroomTitle[Constants.WIDTH]; height:StyleSheet.showroomTitle[Constants.HEIGHT];color:StyleSheet.showroomTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.showroomTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.showroomTitle[Constants.PIXELSIZE];
            id:showroomTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Showroom")
             }
        StdButton {
            x:StyleSheet.showroom_enable[Constants.X]; y:StyleSheet.showroom_enable[Constants.Y]; width:StyleSheet.showroom_enable[Constants.WIDTH]; height:StyleSheet.showroom_enable[Constants.HEIGHT];
            id:showroom; next:back; prev:back;  disabled:false;
            source:
            {
                if (Genivi.showroom==true)
                {
                    source=StyleSheet.showroom_enable[Constants.SOURCE];
                }
                else
                {
                    source=StyleSheet.showroom_disable[Constants.SOURCE];
                }
            }

            function setState(name)
            {
                if (name=="ENABLE")
                {
                    source=StyleSheet.showroom_enable[Constants.SOURCE];
                }
                else
                {
                    source=StyleSheet.showroom_disable[Constants.SOURCE];
                }
            }
            onClicked:
            {
                if (Genivi.showroom ===true)
                {
                    Genivi.showroom=false;
                    showroom.setState("DISABLE");
                }
                else
                {
                    Genivi.showroom=true;
                    showroom.setState("ENABLE");
                }
            }
        }

        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); disabled:false; next:simu_mode; prev:showroom;
            onClicked:{
                disconnectSignals();
                leaveMenu();
            }
        }

	}

    Component.onCompleted: {
        connectSignals();
        var res=Genivi.routing_GetCostModel(dbusIf);
        var costmodel=res[1];
        var costModelsList=Genivi.routing_GetSupportedCostModels(dbusIf);
        for (var i = 0 ; i < costModelsList[1].length ; i+=2) {
            var button=Qt.createQmlObject('import QtQuick 2.1 ; import "Core"; StdButton { }',content,'dynamic');
            button.source=StyleSheet.cost_model[Constants.SOURCE];
            button.x=StyleSheet.cost_model[Constants.X];
            button.y=StyleSheet.cost_model[Constants.Y] + i*(StyleSheet.cost_model[Constants.HEIGHT]+10)/2; //to be improved
            button.width=StyleSheet.cost_model[Constants.WIDTH];
            button.height=StyleSheet.cost_model[Constants.HEIGHT];
            button.textColor=StyleSheet.costModelValue[Constants.TEXTCOLOR];
            button.pixelSize=StyleSheet.costModelValue[Constants.PIXELSIZE];
            button.userdata=costModelsList[1][i+1];
            button.text=Genivi.CostModels[button.userdata];
            button.disabled=button.userdata == costmodel;
            button.clicked.connect(
                function(what) {
                    Genivi.routing_SetCostModel(dbusIf,what.userdata);
                    pageOpen(menu.pagefile); //reload the page
                }
            );
        }

        updateLanguageAndUnits();
        updatePreferences();
    }
}
