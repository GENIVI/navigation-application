/**
* @licence app begin@
* SPDX license identifier: MPL-2.0
*
* \copyright Copyright (C) 2017, PCA Peugeot Citroën
*
*
* \brief This file is part of lbs-fuel-stop-advisor.
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
* <date>, <name>, <description of change>
*
* @licence end@
*/
#ifndef GENIVILOGREPLAYERPLUGIN_H
#define GENIVILOGREPLAYERPLUGIN_H

#include <abstractsource.h>
#include <string>

using namespace std;

class GeniviLogReplayerPlugin: public AbstractSource
{

public:

	GeniviLogReplayerPlugin(AbstractRoutingEngine* re, map<string, string> config);
	~GeniviLogReplayerPlugin();
	const string uuid();
	void getPropertyAsync(AsyncPropertyReply *reply);
	void getRangePropertyAsync(AsyncRangePropertyReply *reply);
	AsyncPropertyReply * setProperty(AsyncSetPropertyRequest request);
	void subscribeToPropertyChanges(VehicleProperty::Property property);
	void unsubscribeToPropertyChanges(VehicleProperty::Property property);
    PropertyList supported();
    int supportedOperations();
    void supportedChanged(const PropertyList &) {}
    PropertyInfo getPropertyInfo(const VehicleProperty::Property & property)
    {
        if(propertyInfoMap.find(property) != propertyInfoMap.end())
            return propertyInfoMap[property];

        return PropertyInfo::invalid();
    }
    int updateProperties();

private:	
    void addPropertySupport(VehicleProperty::Property property, Zone::Type zone);
    std::map<Zone::Type, bool> acStatus;
    std::map<VehicleProperty::Property, PropertyInfo> propertyInfoMap;

    std::string device;
    PropertyList mRequests;
    PropertyList mSupported;

    VehicleProperty::EngineSpeedType enginespeed;
    VehicleProperty::FuelLevelType fuellevel;
    VehicleProperty::FuelConsumptionType fuelcons;
    VehicleProperty::OdometerType odometer;

    // listening loop management and thread
    GThread *thread;
    bool statusRunning = false;
};

#endif // GENIVILOGREPLAYERPLUGIN_H
