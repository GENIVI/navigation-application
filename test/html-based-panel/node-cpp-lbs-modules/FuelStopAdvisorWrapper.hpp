/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2016, PCA Peugeot Citroen
*
* \file FuelStopAdvisorWrapper.hpp
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
#ifndef FUELSTOPADVISERWRAPPER_HPP
#define FUELSTOPADVISERWRAPPER_HPP

#define USE_DBUS 0

#include <node.h>
#include <node_buffer.h>

#include "./dbus-proxies/DemonstratorProxy.hpp"

#include <string>
#include <vector>
#include <map>

// Do not include this line. It's generally frowned upon to use namespaces
// in header files as it may cause issues with other code that includes your
// header file.
// using namespace v8;

class FuelStopAdvisorWrapper : public node::ObjectWrap {
    friend void DemonstratorProxy::TripDataResetted(const uint8_t &number);
    friend void DemonstratorProxy::TripDataUpdated(const uint8_t &number);
    friend void DemonstratorProxy::FuelStopAdvisorWarning(const bool &destinationCantBeReached);

public:
    static v8::Persistent<v8::FunctionTemplate> constructor;
    static void Init(v8::Handle<v8::Object> target);
    static v8::Persistent<v8::Function> signalTripDataUpdated;
    static v8::Persistent<v8::Function> signalFuelStopAdvisorWarning;
    static v8::Persistent<v8::Function> signalTripDataResetted;

protected:
    FuelStopAdvisorWrapper();
    ~FuelStopAdvisorWrapper();

    static v8::Handle<v8::Value> New(const v8::Arguments& args);
    static v8::Handle<v8::Value> GetVersion(const v8::Arguments& args);
    static v8::Handle<v8::Value> GetInstantData(const v8::Arguments& args);

    static v8::Handle<v8::Value> SetTripDataResettedListener(const v8::Arguments& args);
    void TripDataResetted(const uint8_t& number);
    static v8::Handle<v8::Value> SetTripDataUpdatedListener(const v8::Arguments& args);
    void TripDataUpdated(const uint8_t& number);
    static v8::Handle<v8::Value> SetFuelStopAdvisorWarningListener(const v8::Arguments& args);
    void FuelStopAdvisorWarning(const bool& destinationCantBeReached);

    static v8::Handle<v8::Value> GetSpeed(const v8::Arguments& args);
    static v8::Handle<v8::Value> GetLevel(const v8::Arguments& args);
    static v8::Handle<v8::Value> GetInstantConsumption(const v8::Arguments& args);
    static v8::Handle<v8::Value> GetOdometer(const v8::Arguments& args);

private:
    DemonstratorProxy* mp_demonstratorProxy;
};

#endif
