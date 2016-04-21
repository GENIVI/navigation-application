/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2016, PCA Peugeot Citroen
*
* \file main.cpp
*
* \brief This file is part of the Navigation Web API proof of concept.
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
*
* \version 0.1
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
#ifndef NAVIGATIONCOREPROXY_HPP
#define NAVIGATIONCOREPROXY_HPP

#include "genivi-dbus-model.h"

#include <node.h>
#include <node_buffer.h>

#include <string>
#include <vector>
#include <map>

// Do not include this line. It's generally frowned upon to use namespaces
// in header files as it may cause issues with other code that includes your
// header file.
// using namespace v8;


class NavigationCoreProxy;
class NavigationCoreGuidanceProxy
        : public org::genivi::navigationcore::Guidance_proxy,
          public DBus::ObjectProxy
{

public:

    NavigationCoreGuidanceProxy(DBus::Connection &connection,NavigationCoreProxy* navigationCoreProxy);
    void VehicleLeftTheRoadNetwork();
    void GuidanceStatusChanged(const int32_t& guidanceStatus, const uint32_t& routeHandle);
    void WaypointReached(const bool& isDestination);
    void ManeuverChanged(const int32_t& maneuver);
    void PositionOnRouteChanged(const uint32_t& offsetOnRoute);
    void VehicleLeftTheRoute();
    void PositionToRouteChanged(const uint32_t& distance, const int32_t& direction);
    void ActiveRouteChanged(const int32_t& changeCause);

private:
    NavigationCoreProxy* mp_navigationCoreProxy;
};

class NavigationCoreMapMatchedPositionProxy
        : public org::genivi::navigationcore::MapMatchedPosition_proxy,
          public DBus::ObjectProxy
{

public:

    NavigationCoreMapMatchedPositionProxy(DBus::Connection &connection,NavigationCoreProxy* navigationCoreProxy);
    void SimulationStatusChanged(const int32_t& simulationStatus);
    void SimulationSpeedChanged(const uint8_t& speedFactor);
    void PositionUpdate(const std::vector< int32_t >& changedValues);
    void AddressUpdate(const std::vector< int32_t >& changedValues);
    void PositionOnSegmentUpdate(const std::vector< int32_t >& changedValues);
    void StatusUpdate(const std::vector< int32_t >& changedValues);
    void OffRoadPositionChanged(const uint32_t& distance, const int32_t& direction);

private:
    NavigationCoreProxy* mp_navigationCoreProxy;
};

class NavigationCoreWrapper;
class NavigationCoreProxy
{

public:
    NavigationCoreProxy(NavigationCoreWrapper *navigationCoreWrapper);
    ~NavigationCoreProxy();

    void GuidanceStatusChanged(const int32_t& guidanceStatus, const uint32_t& routeHandle);
    void SimulationStatusChanged(const int32_t& simulationStatus);

    NavigationCoreGuidanceProxy* mp_navigationCoreGuidanceProxy;
    NavigationCoreMapMatchedPositionProxy* mp_navigationCoreMapMatchedPositionProxy;

private:
    NavigationCoreWrapper* mp_navigationCoreWrapper;
};

#endif
