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
#include <node.h>

#include "NavigationCoreProxy.hpp"
#include "../NavigationCoreWrapper.hpp"

using namespace v8;
using namespace std;

static DBus::Glib::BusDispatcher *dispatcher;
static DBus::Connection *connection;

NavigationCoreMapMatchedPositionProxy::NavigationCoreMapMatchedPositionProxy(DBus::Connection &connection, NavigationCoreProxy *navigationCoreProxy)
    :    DBus::ObjectProxy(connection,
                           "/org/genivi/navigationcore",
                           "org.genivi.navigationcore.MapMatchedPosition")
{
    mp_navigationCoreProxy = navigationCoreProxy;
}

void NavigationCoreMapMatchedPositionProxy::SimulationStatusChanged(const int32_t& simulationStatus)
{
    mp_navigationCoreProxy->SimulationStatusChanged(simulationStatus);
}

void NavigationCoreMapMatchedPositionProxy::SimulationSpeedChanged(const uint8_t& speedFactor)
{

}

void NavigationCoreMapMatchedPositionProxy::PositionUpdate(const std::vector< int32_t >& changedValues)
{

}

void NavigationCoreMapMatchedPositionProxy::AddressUpdate(const std::vector< int32_t >& changedValues)
{

}

void NavigationCoreMapMatchedPositionProxy::PositionOnSegmentUpdate(const std::vector< int32_t >& changedValues)
{

}

void NavigationCoreMapMatchedPositionProxy::StatusUpdate(const std::vector< int32_t >& changedValues)
{

}

void NavigationCoreMapMatchedPositionProxy::OffRoadPositionChanged(const uint32_t& distance, const int32_t& direction)
{

}

NavigationCoreGuidanceProxy::NavigationCoreGuidanceProxy(DBus::Connection &connection, NavigationCoreProxy *navigationCoreProxy)
    :    DBus::ObjectProxy(connection,
                           "/org/genivi/navigationcore",
                           "org.genivi.navigationcore.Guidance")
{
    mp_navigationCoreProxy = navigationCoreProxy;
}

void NavigationCoreGuidanceProxy::VehicleLeftTheRoadNetwork()
{

}

void NavigationCoreGuidanceProxy::GuidanceStatusChanged(const int32_t& guidanceStatus, const uint32_t& routeHandle)
{
    mp_navigationCoreProxy->GuidanceStatusChanged(guidanceStatus,routeHandle);
}

void NavigationCoreGuidanceProxy::WaypointReached(const bool& isDestination)
{

}

void NavigationCoreGuidanceProxy::ManeuverChanged(const int32_t& maneuver)
{

}

void NavigationCoreGuidanceProxy::PositionOnRouteChanged(const uint32_t& offsetOnRoute)
{

}

void NavigationCoreGuidanceProxy::VehicleLeftTheRoute()
{

}

void NavigationCoreGuidanceProxy::PositionToRouteChanged(const uint32_t& distance, const int32_t& direction)
{

}

void NavigationCoreGuidanceProxy::ActiveRouteChanged(const int32_t& changeCause)
{

}

NavigationCoreProxy::NavigationCoreProxy(NavigationCoreWrapper *navigationCoreWrapper)
{
    dispatcher = new DBus::Glib::BusDispatcher();
    DBus::default_dispatcher = dispatcher;
    dispatcher->attach(NULL);
    connection = new DBus::Connection(DBus::Connection::SessionBus());
    connection->setup(dispatcher);
    mp_navigationCoreWrapper = navigationCoreWrapper;
    mp_navigationCoreGuidanceProxy = new NavigationCoreGuidanceProxy(*connection,this);
    mp_navigationCoreMapMatchedPositionProxy = new NavigationCoreMapMatchedPositionProxy(*connection,this);
}

NavigationCoreProxy::~NavigationCoreProxy()
{
    delete mp_navigationCoreGuidanceProxy;
    delete connection;
    delete dispatcher;
}

void NavigationCoreProxy::GuidanceStatusChanged(const int32_t& guidanceStatus, const uint32_t& routeHandle)
{
    mp_navigationCoreWrapper->GuidanceStatusChanged(guidanceStatus,routeHandle);
}

void NavigationCoreProxy::SimulationStatusChanged(const int32_t& simulationStatus)
{
   mp_navigationCoreWrapper->SimulationStatusChanged(simulationStatus);
}
