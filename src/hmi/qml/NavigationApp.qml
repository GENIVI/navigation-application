/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2017, PSA GROUPE
*
* \file NavigationApp.qml
*
* \brief This file is part of the navigation hmi.
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
*
* \version 1.0
*
* This Source Code Form is subject to the terms of the
* Mozilla Public License (MPL), v. 2.0.
* If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/.
*
* For further information see http://www.genivi.org/.
*
* List of changes:
* <date>, <name>, <description of change>
*
* @licence end@
*/
import QtQuick 2.1 
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import QtQuick.Dialogs 1.0
import "../style-sheets/style-constants.js" as Constants;
import "../style-sheets/NavigationAppBrowseMap-css.js" as StyleSheetMap;
import "Core/genivi.js" as Genivi;
import lbs.plugin.dbusif 1.0
import lbs.plugin.preference 1.0
import lbs.plugin.dltif 1.0

ApplicationWindow {
	id: container
    property string pagefile:"NavigationApp"
    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: true
    width: StyleSheetMap.menu[Constants.WIDTH];
    height: StyleSheetMap.menu[Constants.HEIGHT];
	property Item component;

	function load(page)
	{
		if (component) {
			component.destroy();
		}
		component = Qt.createQmlObject(page+"{}",container,"dynamic");
	}

    function saveSettings()
    {
        Settings.setValue("Settings/simulationMode",Genivi.simulationMode);
        Settings.setValue("Settings/showroom",Genivi.showroom);
        Settings.setValue("Settings/autoguidance",Genivi.autoguidance);
        Settings.setValue("Locale/language",Genivi.g_language)
        Settings.setValue("Locale/country",Genivi.g_country);
        Settings.setValue("Locale/script",Genivi.g_script);
    }

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

    Preference {
        source: 0
        mode: 0
    }

    Connections {
        target: Translator
        onLanguageChanged: {
            var translation = Translator.getCurrentTranslation();
            Genivi.hookMessage(dltIf,"Language updated",translation);
        }
    }

	Component.onCompleted: {

        //init persistent data
        //NB: settings are stored as strings, so it may need some rework for persistent data that are not strings (to be improved ?)
        Genivi.setlang(Settings.getValue("Locale/language"),Settings.getValue("Locale/country"),Settings.getValue("Locale/script"));
        Genivi.setDefaultPosition(Settings.getValue("DefaultPosition/latitude"),Settings.getValue("DefaultPosition/longitude"),Settings.getValue("DefaultPosition/altitude"));
        Genivi.setDefaultAddress(Settings.getValue("DefaultAddress/country"),Settings.getValue("DefaultAddress/city"),Settings.getValue("DefaultAddress/street"),Settings.getValue("DefaultAddress/number"));        
        Genivi.preloadMode=true; //default address loaded
        Genivi.radius=Settings.getValue("Settings/radius");
        Genivi.maxResultListSize=Settings.getValue("Settings/maxResultListSize");
        Genivi.default_category_name=Settings.getValue("Settings/defaultCategoryName")
        if(Settings.getValue("Log/dlt")==="true")
            Genivi.dlt=true;
        else
            Genivi.dlt=false;

        if(Settings.getValue("Settings/simulationMode")==="true")
            Genivi.simulationMode=true;
        else
            Genivi.simulationMode=false;
        if(Settings.getValue("Settings/showroom")==="true")
        {
            Genivi.showroom=true;
            Genivi.mapmatchedposition_SetPosition(dbusIf,dltIf,Genivi.latlon_to_map(Genivi.data['default_position']));
        }
        else
            Genivi.showroom=false;
        if(Settings.getValue("Settings/autoguidance")==="true")
            Genivi.autoguidance=true;
        else
            Genivi.autoguidance=false;
        if(Settings.getValue("Log/verbose")==="true")
            Genivi.verbose=true;
        else
            Genivi.verbose=false;

        //default settings
        Genivi.setGuidanceActivated(dltIf,false);
        Genivi.setRouteCalculated(dltIf,false);
        Genivi.setRerouteRequested(dltIf,false);
        Genivi.setVehicleLocated(dltIf,false);
        Genivi.setDestinationDefined(dltIf,false);

        //configure the middleware
        Genivi.navigationcore_configuration_SetLocale(dbusIf,dltIf,Genivi.g_language,Genivi.g_country,Genivi.g_script);

        //launch the map viewer and init the scale list
        var res0=Genivi.mapviewer_session_CreateSession(dbusIf,dltIf); //only one session managed
        Genivi.g_mapviewer_session_handle[1]=res0[3];
        var res1=Genivi.mapviewer_CreateMapViewInstance(dbusIf,dltIf,width,height,Genivi.MAPVIEWER_MAIN_MAP);
        Genivi.g_mapviewer_handle[1]=res1[3];
        Genivi.initScale(dbusIf,dltIf);
        var res2=Genivi.mapviewer_GetMapViewScale(dbusIf,dltIf);
        Genivi.currentZoomId=res2[1];

        // create a session for navigation core
        var res3=Genivi.navigationcore_session_CreateSession(dbusIf,dltIf);
        Genivi.g_nav_session_handle[1]=res3[3];

        // load the translation file
        var fileName=Genivi.g_language+ "_"+Genivi.g_country+ "_"+Genivi.g_script;
        Translator.setTranslation(fileName);

        //launch the HMI
        Genivi.hookMessage(dltIf,"Menu level",Genivi.entrybackheapsize);
        load("NavigationAppBrowseMap");
	}

    Component.onDestruction:  {
        saveSettings();

        //release all created objects
        var res=Genivi.mapviewer_ReleaseMapViewInstance(dbusIf,dltIf);
        Genivi.g_mapviewer_handle[1]=0;
        var res1=Genivi.mapviewer_session_DeleteSession(dbusIf,dltIf);//only one session managed
        Genivi.g_mapviewer_session_handle[1]=0;
        var res3=Genivi.navigationcore_session_DeleteSession(dbusIf,dltIf);
        Genivi.g_nav_session_handle[1]=0;
    }
}
