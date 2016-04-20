/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2016, PCA Peugeot Citroen
*
* \file FuelStopAdvisorWrapper.cpp
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

#include "FuelStopAdvisorWrapper.hpp"

using namespace std;


v8::Persistent<v8::FunctionTemplate> FuelStopAdvisorWrapper::constructor;

v8::Persistent<v8::Function> FuelStopAdvisorWrapper::signalTripDataUpdated;

void FuelStopAdvisorWrapper::TripDataUpdated(const uint8_t& number)
{
    v8::HandleScope scope();

    const unsigned argc = 1;
    v8::Local<v8::Value> argv[argc];

    argv[0]=v8::Local<v8::Value>::New(v8::Integer::New(number));

    v8::Persistent<v8::Function> fct = static_cast<v8::Function*>(*signalTripDataUpdated);
    fct->Call(v8::Context::GetCurrent()->Global(), argc, argv);
}

v8::Handle<v8::Value> FuelStopAdvisorWrapper::SetTripDataUpdatedListener(const v8::Arguments& args)
{
    v8::HandleScope scope; //to properly clean up v8 handles

    if (!args[0]->IsFunction()) {
        return v8::ThrowException(
        v8::Exception::TypeError(v8::String::New("Requires a function as parameter"))
        );
    }

    signalTripDataUpdated = v8::Persistent<v8::Function>::New(v8::Handle<v8::Function>::Cast(args[0]));

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Boolean::New(signalTripDataUpdated->IsFunction()) );

    return scope.Close(ret);
}

v8::Persistent<v8::Function> FuelStopAdvisorWrapper::signalFuelStopAdvisorWarning;

void FuelStopAdvisorWrapper::FuelStopAdvisorWarning(const bool &destinationCantBeReached)
{
    v8::HandleScope scope;

    const unsigned argc = 1;
    v8::Local<v8::Value> argv[argc];

    argv[0]=v8::Local<v8::Value>::New(v8::Boolean::New(destinationCantBeReached));

    v8::Persistent<v8::Function> fct = static_cast<v8::Function*>(*signalFuelStopAdvisorWarning);
    fct->Call(v8::Context::GetCurrent()->Global(), argc, argv);
}

v8::Handle<v8::Value> FuelStopAdvisorWrapper::SetFuelStopAdvisorWarningListener(const v8::Arguments& args)
{
    v8::HandleScope scope; //to properly clean up v8 handles

    if (!args[0]->IsFunction()) {
        return v8::ThrowException(
        v8::Exception::TypeError(v8::String::New("Requires a function as parameter"))
        );
    }

    signalFuelStopAdvisorWarning = v8::Persistent<v8::Function>::New(v8::Handle<v8::Function>::Cast(args[0]));

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Boolean::New(signalFuelStopAdvisorWarning->IsFunction()) );

    return scope.Close(ret);
}

v8::Persistent<v8::Function> FuelStopAdvisorWrapper::signalTripDataResetted;

void FuelStopAdvisorWrapper::TripDataResetted(const uint8_t& number)
{
    v8::HandleScope scope;

    const unsigned argc = 1;
    v8::Local<v8::Value> argv[argc];

    argv[0]=v8::Local<v8::Value>::New(v8::Integer::New(number));

    v8::Persistent<v8::Function> fct = static_cast<v8::Function*>(*signalTripDataResetted);
    fct->Call(v8::Context::GetCurrent()->Global(), argc, argv);
}

v8::Handle<v8::Value> FuelStopAdvisorWrapper::SetTripDataResettedListener(const v8::Arguments& args)
{
    v8::HandleScope scope; //to properly clean up v8 handles

    if (!args[0]->IsFunction()) {
        return v8::ThrowException(
        v8::Exception::TypeError(v8::String::New("Requires a function as parameter"))
        );
    }

    signalTripDataResetted = v8::Persistent<v8::Function>::New(v8::Handle<v8::Function>::Cast(args[0]));

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Boolean::New(signalTripDataResetted->IsFunction()) );

    return scope.Close(ret);
}

void FuelStopAdvisorWrapper::Init(v8::Handle<v8::Object> target) {
    v8::HandleScope scope;

    v8::Local<v8::FunctionTemplate> tpl = v8::FunctionTemplate::New(New);
    v8::Local<v8::String> name = v8::String::NewSymbol("FuelStopAdvisorWrapper");

    constructor = v8::Persistent<v8::FunctionTemplate>::New(tpl);
    // ObjectWrap uses the first internal field to store the wrapped pointer.
    constructor->InstanceTemplate()->SetInternalFieldCount(1);
    constructor->SetClassName(name);

    // Add all prototype methods, getters and setters here.
    NODE_SET_PROTOTYPE_METHOD(constructor, "getVersion", GetVersion);
    NODE_SET_PROTOTYPE_METHOD(constructor, "getInstantData", GetInstantData);
    NODE_SET_PROTOTYPE_METHOD(constructor, "setTripDataUpdatedListener", SetTripDataUpdatedListener);
    NODE_SET_PROTOTYPE_METHOD(constructor, "setFuelStopAdvisorWarningListener", SetFuelStopAdvisorWarningListener);
    NODE_SET_PROTOTYPE_METHOD(constructor, "setTripDataResettedListener", SetTripDataResettedListener);
    NODE_SET_PROTOTYPE_METHOD(constructor, "getSpeed", GetSpeed);
    NODE_SET_PROTOTYPE_METHOD(constructor, "getLevel", GetLevel);
    NODE_SET_PROTOTYPE_METHOD(constructor, "getInstantConsumption", GetInstantConsumption);
    NODE_SET_PROTOTYPE_METHOD(constructor, "getOdometer", GetOdometer);

    // This has to be last, otherwise the properties won't show up on the
    // object in JavaScript.
    target->Set(name, constructor->GetFunction());
}

FuelStopAdvisorWrapper::FuelStopAdvisorWrapper() {
}

FuelStopAdvisorWrapper::~FuelStopAdvisorWrapper() {
}

v8::Handle<v8::Value> FuelStopAdvisorWrapper::New(const v8::Arguments& args) {
    v8::HandleScope scope;

    if (!args.IsConstructCall()) {
        return v8::ThrowException(v8::Exception::TypeError(
            v8::String::New("Use the new operator to create instances of this object."))
        );
    }

    // Creates a new instance object of this type and wraps it.
    FuelStopAdvisorWrapper* obj = new FuelStopAdvisorWrapper();

    DemonstratorProxy* proxy = new DemonstratorProxy(obj);
    obj->mp_demonstratorProxy = proxy;
    obj->Wrap(args.This());

    return args.This();
}

v8::Handle<v8::Value> FuelStopAdvisorWrapper::GetVersion(const v8::Arguments& args) {
    v8::HandleScope scope; //to properly clean up v8 handles

    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    ::DBus::Struct< uint16_t, uint16_t, uint16_t, std::string > DBus_version = obj->mp_demonstratorProxy->mp_fuelStopAdvisorProxy->GetVersion();

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Int32::New(DBus_version._1) );
    ret->Set( 1, v8::Int32::New(DBus_version._2) );
    ret->Set( 2, v8::Int32::New(DBus_version._3) );
    ret->Set( 3, v8::String::New(DBus_version._4.c_str()) );

    return scope.Close(ret);
}

v8::Handle<v8::Value> FuelStopAdvisorWrapper::GetInstantData(const v8::Arguments& args) {
    v8::HandleScope scope; //to properly clean up v8 handles

    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    std::map< uint16_t, ::DBus::Variant > instant_data = obj->mp_demonstratorProxy->mp_fuelStopAdvisorProxy->GetInstantData();


    v8::Local<v8::Array> ret = v8::Array::New();

    for (std::map< uint16_t, ::DBus::Variant >::iterator iter = instant_data.begin(); iter != instant_data.end(); iter++) {
        v8::Local<v8::Object> data = v8::Object::New();
        ::DBus::Variant value = iter->second;
        printf("GetInstantData%d\n",iter->first);
        printf("GetInstantData%s\n",value.signature().c_str());
        data->Set(v8::String::New("key"), v8::Uint32::New(iter->first));
        switch (iter->first) {
        case GENIVI_FUELSTOPADVISOR_FUEL_LEVEL:
            data->Set(v8::String::New("value"), v8::Int32::New(15));
            break;
        case GENIVI_FUELSTOPADVISOR_INSTANT_FUEL_CONSUMPTION_PER_DISTANCE:
            data->Set(v8::String::New("value"), v8::Int32::New(55));
            break;
        case GENIVI_FUELSTOPADVISOR_TANK_DISTANCE:
            data->Set(v8::String::New("value"), v8::Int32::New(300));
            break;
        case GENIVI_FUELSTOPADVISOR_ENHANCED_TANK_DISTANCE:
            data->Set(v8::String::New("value"), v8::Int32::New(400));
            break;
        default:
            break;
        }
        ret->Set(ret->Length(), data);
    }

    return scope.Close(ret);
}

v8::Handle<v8::Value> FuelStopAdvisorWrapper::GetSpeed(const v8::Arguments& args) {
    v8::HandleScope scope; //to properly clean up v8 handles

    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    v8::Local<v8::Object> ret = v8::Object::New();

    return scope.Close(ret);
}

v8::Handle<v8::Value> FuelStopAdvisorWrapper::GetLevel(const v8::Arguments& args) {
    v8::HandleScope scope; //to properly clean up v8 handles

    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    DBus::Variant variant = obj->mp_demonstratorProxy->mp_managerProxy->GetLevel();
    DBus::MessageIter it = variant.reader();
    uint16_t level;
    it >> level;

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Uint32::New(level) );

    return scope.Close(ret);
}

v8::Handle<v8::Value> FuelStopAdvisorWrapper::GetInstantConsumption(const v8::Arguments& args) {
    v8::HandleScope scope; //to properly clean up v8 handles

    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    DBus::Variant variant = obj->mp_demonstratorProxy->mp_managerProxy->GetInstantConsumption();
    DBus::MessageIter it = variant.reader();
    uint32_t consumption;
    it >> consumption;

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Uint32::New(consumption) );

    return scope.Close(ret);
}

v8::Handle<v8::Value> FuelStopAdvisorWrapper::GetOdometer(const v8::Arguments& args) {
    v8::HandleScope scope; //to properly clean up v8 handles

    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    v8::Local<v8::Object> ret = v8::Object::New();

    return scope.Close(ret);
}



void RegisterModule(v8::Handle<v8::Object> target) {
    FuelStopAdvisorWrapper::Init(target);
}

NODE_MODULE(FuelStopAdvisorWrapper, RegisterModule);
