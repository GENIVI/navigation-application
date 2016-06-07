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
#include <node_object_wrap.h>

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
    static v8::Persistent<v8::Function> constructor;
    static void Init(v8::Local<v8::Object> target);
    static void NewInstance(const v8::FunctionCallbackInfo<v8::Value>& args);
    static v8::Persistent<v8::Function> signalTripDataUpdated;
    static v8::Persistent<v8::Function> signalFuelStopAdvisorWarning;
    static v8::Persistent<v8::Function> signalTripDataResetted;

protected:
    FuelStopAdvisorWrapper();
    ~FuelStopAdvisorWrapper();

    static void New(const v8::FunctionCallbackInfo<v8::Value> &args);
    static void GetVersion(const v8::FunctionCallbackInfo<v8::Value> &args);
    static void GetInstantData(const v8::FunctionCallbackInfo<v8::Value> &args);

    static void SetTripDataResettedListener(const v8::FunctionCallbackInfo<v8::Value> &args);
    void TripDataResetted(const uint8_t& number);
    static void SetTripDataUpdatedListener(const v8::FunctionCallbackInfo<v8::Value> &args);
    void TripDataUpdated(const uint8_t& number);
    static void SetFuelStopAdvisorWarningListener(const v8::FunctionCallbackInfo<v8::Value> &args);
    void FuelStopAdvisorWarning(const bool& destinationCantBeReached);

    static void GetSpeed(const v8::FunctionCallbackInfo<v8::Value> &args);
    static void GetLevel(const v8::FunctionCallbackInfo<v8::Value> &args);
    static void GetInstantConsumption(const v8::FunctionCallbackInfo<v8::Value> &args);
    static void GetOdometer(const v8::FunctionCallbackInfo<v8::Value> &args);

private:
    DemonstratorProxy* mp_demonstratorProxy;
};

#endif
