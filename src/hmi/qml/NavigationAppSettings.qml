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
import "../style-sheets/style-constants.js" as Constants;
import "../style-sheets/NavigationAppSettings-css.js" as StyleSheet;
import lbs.plugin.dbusif 1.0
import lbs.plugin.dltif 1.0

NavigationAppHMIMenu {
	id: menu
    property string pagefile:"NavigationAppSettings"
    next: back
    prev: back

    DLTIf {
        id:dltIf;
        name: pagefile;
    }

    //------------------------------------------//
    // Management of the DBus exchanges
    //------------------------------------------//
    DBusIf {
		id:dbusIf;
	}

    property Item configurationChangedSignal;
    function configurationChanged(args)
    { //to be improved !
        Genivi.hookSignal(dltIf,"configurationChanged");
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
        var available_nav=Genivi.navigationcore_configuration_GetSupportedLocales(dbusIf,dltIf);
        var available_map=Genivi.mapviewer_configuration_GetSupportedLocales(dbusIf,dltIf);
        var current_nav=Genivi.navigationcore_configuration_GetLocale(dbusIf,dltIf);
        var current_map=Genivi.mapviewer_configuration_GetLocale(dbusIf,dltIf);
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

        Genivi.setlang(current_nav[1],current_nav[3],current_nav[5]);

        var units1,units2;
        var res=Genivi.navigationcore_configuration_GetUnitsOfMeasurement(dbusIf,dltIf);

        if (res[1][1] == Genivi.NAVIGATIONCORE_LENGTH) {
            units1=res[1][3];
        }
        var res1=Genivi.mapviewer_configuration_GetUnitsOfMeasurement(dbusIf,dltIf);
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
        Genivi.navigationcore_configuration_SetLocale(dbusIf,dltIf,language,country,script);
        Genivi.mapviewer_configuration_SetLocale(dbusIf,dltIf,language,country,script);
        Genivi.setlang(language,country,script);
        pageOpen(dltIf,menu.pagefile); //reload page because of texts...
    }

    function setUnitsLength(units1,units2)
    {
        Genivi.navigationcore_configuration_SetUnitsOfMeasurementLength(dbusIf,dltIf,units1);
        Genivi.mapviewer_configuration_SetUnitsOfMeasurementLength(dbusIf,dltIf,units2);
        updateLanguageAndUnits();
    }

    //------------------------------------------//
    // Management of the preferences
    //------------------------------------------//
    // please note that the preferences are hard coded, limited to three couples:
    //    (NAVIGATIONCORE_AVOID,NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)
    //    (NAVIGATIONCORE_AVOID,NAVIGATIONCORE_TOLL_ROADS)
    //    (NAVIGATIONCORE_AVOID,NAVIGATIONCORE_FERRY)

    function updatePreferences()
    {
        Genivi.routing_SetRoutePreferences(dbusIf,dltIf,""); //preferences applied to all countries
        var active=Genivi.routing_GetRoutePreferences(dbusIf,dltIf,"");

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

    function updateSettings()
    {
        if (Genivi.autoguidance===true)
        {
            autoguidance.setState("ENABLE");
        }
        else
        {
            autoguidance.setState("DISABLE");
        }
        if (Genivi.simulationMode===true)
        {
            simu_mode.setState("ENABLE");
        }
        else
        {
            simu_mode.setState("DISABLE");
        }
        if (Genivi.showroom===true)
        {
            showroom.setState("ENABLE");
        }
        else
        {
            showroom.setState("DISABLE");
        }
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
            id:fra_FRA; disabled:false;onClicked: {setLocale("fra","FRA","Latn");}}
        StdButton { objectName:"deu_DEU";
            source:StyleSheet.german_flag[Constants.SOURCE]; x:StyleSheet.german_flag[Constants.X]; y:StyleSheet.german_flag[Constants.Y]; width:StyleSheet.german_flag[Constants.WIDTH]; height:StyleSheet.german_flag[Constants.HEIGHT];
             id:deu_DEU; disabled:false;onClicked: {setLocale("deu","DEU","Latn");}}
        StdButton { objectName:"eng_USA";
            source:StyleSheet.usa_flag[Constants.SOURCE]; x:StyleSheet.usa_flag[Constants.X]; y:StyleSheet.usa_flag[Constants.Y]; width:StyleSheet.usa_flag[Constants.WIDTH]; height:StyleSheet.usa_flag[Constants.HEIGHT];
            id:eng_USA; disabled:false;onClicked: {setLocale("eng","USA","Latn");}}
        StdButton { objectName:"jpn_JPN";
            source:StyleSheet.japanese_flag[Constants.SOURCE]; x:StyleSheet.japanese_flag[Constants.X]; y:StyleSheet.japanese_flag[Constants.Y]; width:StyleSheet.japanese_flag[Constants.WIDTH]; height:StyleSheet.japanese_flag[Constants.HEIGHT];
            id:jpn_JPN; disabled:false;onClicked: {setLocale("jpn","JPN","Hrkt");}}

        Text {
            x:StyleSheet.unitsTitle[Constants.X]; y:StyleSheet.unitsTitle[Constants.Y]; width:StyleSheet.unitsTitle[Constants.WIDTH]; height:StyleSheet.unitsTitle[Constants.HEIGHT];color:StyleSheet.unitsTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.unitsTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.unitsTitle[Constants.PIXELSIZE];
            id:unitsTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Units")
             }
        StdButton { source:StyleSheet.unit_km[Constants.SOURCE]; x:StyleSheet.unit_km[Constants.X]; y:StyleSheet.unit_km[Constants.Y]; width:StyleSheet.unit_km[Constants.WIDTH]; height:StyleSheet.unit_km[Constants.HEIGHT];
            id:unit_km;  disabled:false;
            onClicked: {
                setUnitsLength(Genivi.NAVIGATIONCORE_KM,Genivi.MAPVIEWER_KM);}
        }
        StdButton { source:StyleSheet.unit_mile[Constants.SOURCE]; x:StyleSheet.unit_mile[Constants.X]; y:StyleSheet.unit_mile[Constants.Y]; width:StyleSheet.unit_mile[Constants.WIDTH]; height:StyleSheet.unit_mile[Constants.HEIGHT];
            id:unit_mile;  disabled:false;
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
            id:ferries_yes;disabled: !Genivi.route_calculated;onClicked:{use(Genivi.NAVIGATIONCORE_FERRY)}}
        StdButton { source:StyleSheet.avoid_ferries[Constants.SOURCE]; x:StyleSheet.avoid_ferries[Constants.X]; y:StyleSheet.avoid_ferries[Constants.Y]; width:StyleSheet.avoid_ferries[Constants.WIDTH]; height:StyleSheet.avoid_ferries[Constants.HEIGHT];
            id:ferries_no;disabled: !Genivi.route_calculated;onClicked:{avoid(Genivi.NAVIGATIONCORE_FERRY)}}

        Text {
            x:StyleSheet.tollRoadsText[Constants.X]; y:StyleSheet.tollRoadsText[Constants.Y]; width:StyleSheet.tollRoadsText[Constants.WIDTH]; height:StyleSheet.tollRoadsText[Constants.HEIGHT];color:StyleSheet.tollRoadsText[Constants.TEXTCOLOR];styleColor:StyleSheet.tollRoadsText[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.tollRoadsText[Constants.PIXELSIZE];
            id: tollRoadsText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("TollRoads")
        }
        StdButton { source:StyleSheet.allow_tollRoads[Constants.SOURCE]; x:StyleSheet.allow_tollRoads[Constants.X]; y:StyleSheet.allow_tollRoads[Constants.Y]; width:StyleSheet.allow_tollRoads[Constants.WIDTH]; height:StyleSheet.allow_tollRoads[Constants.HEIGHT];
            id:toll_roads_yes;disabled: !Genivi.route_calculated;onClicked:{use(Genivi.NAVIGATIONCORE_TOLL_ROADS)}}
        StdButton { source:StyleSheet.avoid_tollRoads[Constants.SOURCE]; x:StyleSheet.avoid_tollRoads[Constants.X]; y:StyleSheet.avoid_tollRoads[Constants.Y]; width:StyleSheet.avoid_tollRoads[Constants.WIDTH]; height:StyleSheet.avoid_tollRoads[Constants.HEIGHT];
            id:toll_roads_no;disabled: !Genivi.route_calculated;onClicked:{avoid(Genivi.NAVIGATIONCORE_TOLL_ROADS)}}

        Text {
            x:StyleSheet.motorWaysText[Constants.X]; y:StyleSheet.motorWaysText[Constants.Y]; width:StyleSheet.motorWaysText[Constants.WIDTH]; height:StyleSheet.motorWaysText[Constants.HEIGHT];color:StyleSheet.motorWaysText[Constants.TEXTCOLOR];styleColor:StyleSheet.motorWaysText[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.motorWaysText[Constants.PIXELSIZE];
            id:motorWaysText;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("MotorWays")
        }
        StdButton { source:StyleSheet.allow_motorways[Constants.SOURCE]; x:StyleSheet.allow_motorways[Constants.X]; y:StyleSheet.allow_motorways[Constants.Y]; width:StyleSheet.allow_motorways[Constants.WIDTH]; height:StyleSheet.allow_motorways[Constants.HEIGHT];
            id:motorways_yes;disabled: !Genivi.route_calculated;onClicked:{use(Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}
        StdButton { source:StyleSheet.avoid_motorways[Constants.SOURCE]; x:StyleSheet.avoid_motorways[Constants.X]; y:StyleSheet.avoid_motorways[Constants.Y]; width:StyleSheet.avoid_motorways[Constants.WIDTH]; height:StyleSheet.avoid_motorways[Constants.HEIGHT];
            id:motorways_no;disabled: !Genivi.route_calculated;onClicked:{avoid(Genivi.NAVIGATIONCORE_HIGHWAYS_MOTORWAYS)}}

		Text {
            x:StyleSheet.simulationTitle[Constants.X]; y:StyleSheet.simulationTitle[Constants.Y]; width:StyleSheet.simulationTitle[Constants.WIDTH]; height:StyleSheet.simulationTitle[Constants.HEIGHT];color:StyleSheet.simulationTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.simulationTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.simulationTitle[Constants.PIXELSIZE];
            id:simulationTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Simulation")
             }
        StdButton {
            x:StyleSheet.simu_mode_enable[Constants.X]; y:StyleSheet.simu_mode_enable[Constants.Y]; width:StyleSheet.simu_mode_enable[Constants.WIDTH]; height:StyleSheet.simu_mode_enable[Constants.HEIGHT];
            id:simu_mode;disabled:false;
            source:StyleSheet.simu_mode_enable[Constants.SOURCE];
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
                    Genivi.mapmatchedposition_SetSimulationMode(dbusIf,dltIf,false);
                    simu_mode.setState("DISABLE");
                }
                else
                {
                    Genivi.simulationMode=true;
                    Genivi.mapmatchedposition_SetSimulationMode(dbusIf,dltIf,true);
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
            source: StyleSheet.showroom_disable[Constants.SOURCE];
            function setState(name)
            {
                if (name==="ENABLE")
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
                if (Genivi.showroom===true)
                {
                    Genivi.showroom=false;
                    showroom.setState("DISABLE");
                }
                else
                {
                    Genivi.showroom=true;
                    Genivi.mapmatchedposition_SetPosition(dbusIf,dltIf,Genivi.latlon_to_map(Genivi.data['default_position']));
                    showroom.setState("ENABLE");
                }
            }
        }

        Text {
            x:StyleSheet.autoguidanceTitle[Constants.X]; y:StyleSheet.autoguidanceTitle[Constants.Y]; width:StyleSheet.autoguidanceTitle[Constants.WIDTH]; height:StyleSheet.autoguidanceTitle[Constants.HEIGHT];color:StyleSheet.autoguidanceTitle[Constants.TEXTCOLOR];styleColor:StyleSheet.autoguidanceTitle[Constants.STYLECOLOR]; font.pixelSize:StyleSheet.autoguidanceTitle[Constants.PIXELSIZE];
            id:autoguidanceTitle;
            style: Text.Sunken;
            smooth: true
            text: Genivi.gettext("Autoguidance")
             }
        StdButton {
            x:StyleSheet.autoguidance_enable[Constants.X]; y:StyleSheet.autoguidance_enable[Constants.Y]; width:StyleSheet.autoguidance_enable[Constants.WIDTH]; height:StyleSheet.autoguidance_enable[Constants.HEIGHT];
            id:autoguidance; next:back; prev:back;  disabled:false;
            source: StyleSheet.autoguidance_disable[Constants.SOURCE];
            function setState(name)
            {
                if (name=="ENABLE")
                {
                    source=StyleSheet.autoguidance_enable[Constants.SOURCE];
                }
                else
                {
                    source=StyleSheet.autoguidance_disable[Constants.SOURCE];
                }
            }
            onClicked:
            {
                if (Genivi.autoguidance ===true)
                {
                    Genivi.autoguidance=false;
                    autoguidance.setState("DISABLE");
                }
                else
                {
                    Genivi.autoguidance=true;
                    autoguidance.setState("ENABLE");
                }
            }
        }

        StdButton {
            source:StyleSheet.mapDataBase[Constants.SOURCE]; x:StyleSheet.mapDataBase[Constants.X]; y:StyleSheet.mapDataBase[Constants.Y]; width:StyleSheet.mapDataBase[Constants.WIDTH]; height:StyleSheet.mapDataBase[Constants.HEIGHT];textColor:StyleSheet.mapDataBaseText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.mapDataBaseText[Constants.PIXELSIZE];
            id:mapDataBase; text: Genivi.gettext("Mapview"); disabled:false;
            onClicked:{
                disconnectSignals();
                entryMenu(dltIf,"NavigationAppMap",menu);
            }
        }

        StdButton {
            source:StyleSheet.back[Constants.SOURCE]; x:StyleSheet.back[Constants.X]; y:StyleSheet.back[Constants.Y]; width:StyleSheet.back[Constants.WIDTH]; height:StyleSheet.back[Constants.HEIGHT];textColor:StyleSheet.backText[Constants.TEXTCOLOR]; pixelSize:StyleSheet.backText[Constants.PIXELSIZE];
            id:back; text: Genivi.gettext("Back"); disabled:false;
            onClicked:{
                disconnectSignals();
                leaveMenu(dltIf);
            }
        }

	}

    Component.onCompleted: {
        connectSignals();

        if(Genivi.route_calculated){
            var res=Genivi.routing_GetCostModel(dbusIf,dltIf);
            var costmodel=res[1];
        }
        var costModelsList=Genivi.routing_GetSupportedCostModels(dbusIf,dltIf);
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
            if(Genivi.route_calculated){
                button.disabled=button.userdata === costmodel;
            }else{
                button.disabled=true;
            }

            button.clicked.connect(
                function(what) {
                    Genivi.routing_SetCostModel(dbusIf,dltIf,what.userdata);
                    pageOpen(dltIf,menu.pagefile); //reload the page
                }
            );
        }

        updateLanguageAndUnits();
        updatePreferences();
        updateSettings();
    }
}
