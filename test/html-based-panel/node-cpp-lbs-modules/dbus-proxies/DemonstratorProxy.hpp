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
#ifndef FUELSTOPADVISORPROXY_HPP
#define FUELSTOPADVISORPROXY_HPP

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

class DemonstratorProxy;
class FuelStopAdvisorProxy
        : public org::genivi::demonstrator::FuelStopAdvisor_proxy,
          public DBus::ObjectProxy
{
public:

    FuelStopAdvisorProxy(DBus::Connection &connection,DemonstratorProxy* demonstratorProxy);
    void TripDataResetted(const uint8_t& number);
    void TripDataUpdated(const uint8_t& number);
    void FuelStopAdvisorWarning(const bool& destinationCantBeReached);

private:
    DemonstratorProxy* mp_demonstratorProxy;
};

class Properties
: public ::DBus::InterfaceProxy,
  public ::DBus::ObjectProxy
{
    public:

    Properties(::DBus::Connection &connection, ::DBus::Path path)
        : ::DBus::InterfaceProxy("org.freedesktop.DBus.Properties"),
        ::DBus::ObjectProxy(connection, path,"org.automotive.message.broker")
    {
    }
    ::DBus::Variant Get(const std::string &iface, const std::string &property)
    {
        ::DBus::CallMessage call;
        ::DBus::MessageIter wi = call.writer();

        wi << iface;
        wi << property;
        call.member("Get");
        ::DBus::Message ret = invoke_method (call);
        ::DBus::MessageIter ri = ret.reader();
        ::DBus::Variant argout;
        ri >> argout;
        return argout;
    }
};

class ManagerProxy
        : public org::automotive::Manager_proxy,
          public DBus::ObjectProxy
{
public:

    ManagerProxy(DBus::Connection &connection, DemonstratorProxy *demonstratorProxy);
    std::vector< ::DBus::Path > m_fuel;
    std::vector< ::DBus::Path > m_odometer;
    std::vector< ::DBus::Path > m_engine_speed;
    Properties *mp_fuel_properties;
    Properties *mp_odometer_properties;
    Properties *mp_engine_speed_properties;

    DBus::Variant GetLevel();
    DBus::Variant GetSpeed();
    DBus::Variant GetInstantConsumption();
    DBus::Variant GetOdometer();

private:
    DemonstratorProxy* mp_demonstratorProxy;

};

class FuelStopAdvisorWrapper;
class DemonstratorProxy
{
public:
    DemonstratorProxy(FuelStopAdvisorWrapper* fuelStopAdvisorWrapper);
    ~DemonstratorProxy();

    FuelStopAdvisorProxy* mp_fuelStopAdvisorProxy;
    void TripDataResetted(const uint8_t& number);
    void TripDataUpdated(const uint8_t& number);
    void FuelStopAdvisorWarning(const bool& destinationCantBeReached);

    ManagerProxy* mp_managerProxy;

private:
    FuelStopAdvisorWrapper* mp_fuelStopAdvisorWrapper;
};

#endif
