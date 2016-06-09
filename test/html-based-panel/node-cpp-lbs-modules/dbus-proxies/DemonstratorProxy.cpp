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

#include "DemonstratorProxy.hpp"
#include "../FuelStopAdvisorWrapper.hpp"

using namespace v8;
using namespace std;

static DBus::Glib::BusDispatcher *dispatcher;
static DBus::Connection *connection;
static DBus::Glib::BusDispatcher *amb_dispatcher;
static DBus::Connection *amb_connection;

FuelStopAdvisorProxy::FuelStopAdvisorProxy(DBus::Connection &connection, DemonstratorProxy *demonstratorProxy)
    :    DBus::ObjectProxy(connection,
                           "/org/genivi/demonstrator/FuelStopAdvisor",
                           "org.genivi.demonstrator.FuelStopAdvisor")
{
    mp_demonstratorProxy = demonstratorProxy;
}

void FuelStopAdvisorProxy::TripDataResetted(const uint8_t& number)
{
    mp_demonstratorProxy->TripDataResetted(number);
}

void FuelStopAdvisorProxy::TripDataUpdated(const uint8_t& number)
{
    mp_demonstratorProxy->TripDataUpdated(number);
}

void FuelStopAdvisorProxy::FuelStopAdvisorWarning(const bool& destinationCantBeReached)
{
    mp_demonstratorProxy->FuelStopAdvisorWarning(destinationCantBeReached);
}

ManagerProxy::ManagerProxy(DBus::Connection &connection, DemonstratorProxy *demonstratorProxy)
    : DBus::ObjectProxy(connection,
                        "/",
                        "org.automotive.message.broker")
{
    mp_demonstratorProxy = demonstratorProxy;
}

DBus::Variant ManagerProxy::GetLevel()
{
    return (mp_fuel_properties->Get("org.automotive.Fuel","Level"));
}

DBus::Variant ManagerProxy::GetSpeed()
{
    return (mp_engine_speed_properties->Get("org.automotive.EngineSpeed","Speed"));
}

DBus::Variant ManagerProxy::GetInstantConsumption()
{
    return (mp_fuel_properties->Get("org.automotive.Fuel","InstantConsumption"));
}

DBus::Variant ManagerProxy::GetOdometer()
{
    return(mp_odometer_properties->Get("org.automotive.Odometer","Odometer"));
}

DemonstratorProxy::DemonstratorProxy(FuelStopAdvisorWrapper *fuelStopAdvisorWrapper)
{
    dispatcher = new DBus::Glib::BusDispatcher();
    DBus::default_dispatcher = dispatcher;
    dispatcher->attach(NULL);
    connection = new DBus::Connection(DBus::Connection::SessionBus());
    connection->setup(dispatcher);
    mp_fuelStopAdvisorWrapper = fuelStopAdvisorWrapper;
    mp_fuelStopAdvisorProxy = new FuelStopAdvisorProxy(*connection,this);

    amb_dispatcher = new DBus::Glib::BusDispatcher();
    DBus::default_dispatcher = amb_dispatcher;
    amb_dispatcher->attach(NULL);
    amb_connection = new DBus::Connection(DBus::Connection::SessionBus());
    amb_connection->setup(amb_dispatcher);

    mp_managerProxy = new ManagerProxy(*amb_connection, this);

    mp_managerProxy->m_fuel = mp_managerProxy->FindObject("Fuel");
    mp_managerProxy->m_odometer = mp_managerProxy->FindObject("Odometer");
    mp_managerProxy->m_engine_speed = mp_managerProxy->FindObject("EngineSpeed");

    mp_managerProxy->mp_fuel_properties = new Properties(*amb_connection,mp_managerProxy->m_fuel[0]);
    mp_managerProxy->mp_odometer_properties = new Properties(*amb_connection,mp_managerProxy->m_odometer[0]);
    mp_managerProxy->mp_engine_speed_properties = new Properties(*amb_connection,mp_managerProxy->m_engine_speed[0]);

}

DemonstratorProxy::~DemonstratorProxy()
{
    delete mp_fuelStopAdvisorProxy;
    delete mp_managerProxy;
    delete connection;
    delete dispatcher;
    delete amb_connection;
    delete amb_dispatcher;
}

void DemonstratorProxy::TripDataResetted(const uint8_t& number)
{
    mp_fuelStopAdvisorWrapper->TripDataResetted(number);
}

void DemonstratorProxy::TripDataUpdated(const uint8_t& number)
{
    mp_fuelStopAdvisorWrapper->TripDataUpdated(number);
}

void DemonstratorProxy::FuelStopAdvisorWarning(const bool& destinationCantBeReached)
{
    mp_fuelStopAdvisorWrapper->FuelStopAdvisorWarning(destinationCantBeReached);
}
