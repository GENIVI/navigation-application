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


v8::Persistent<v8::Function> FuelStopAdvisorWrapper::constructor;

v8::Persistent<v8::Function> FuelStopAdvisorWrapper::signalTripDataUpdated;

void FuelStopAdvisorWrapper::TripDataUpdated(const uint8_t& number)
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    v8::HandleScope handleScope(isolate);
    const unsigned argc = 1;
    v8::Local<v8::Value> argv[argc];

    argv[0]=v8::Local<v8::Value>::New(isolate,v8::Integer::New(isolate,number));

    v8::Local<v8::Function> fct = v8::Local<v8::Function>::New(isolate,signalTripDataUpdated);
    fct->Call(isolate->GetCurrentContext()->Global(), argc, argv);
}

void FuelStopAdvisorWrapper::SetTripDataUpdatedListener(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    v8::Isolate* isolate = args.GetIsolate();

    if (!args[0]->IsFunction()) {
        isolate->ThrowException(
        v8::Exception::TypeError(v8::String::NewFromUtf8(isolate,"Requires a function as parameter"))
        );
    }
    v8::Local<v8::Function> fct = v8::Local<v8::Function>::Cast(args[0]);
    v8::Persistent<v8::Function> persfct(isolate,fct);
    signalTripDataUpdated.Reset(isolate,persfct);;

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Boolean::New(isolate, v8::True) );

    args.GetReturnValue().Set(ret);
}

v8::Persistent<v8::Function> FuelStopAdvisorWrapper::signalFuelStopAdvisorWarning;

void FuelStopAdvisorWrapper::FuelStopAdvisorWarning(const bool &destinationCantBeReached)
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    v8::HandleScope handleScope(isolate);
    const unsigned argc = 1;
    v8::Local<v8::Value> argv[argc];

    argv[0]=v8::Local<v8::Value>::New(isolate,v8::Boolean::New(isolate,destinationCantBeReached));

    v8::Local<v8::Function> fct= v8::Local<v8::Function>::New(isolate,signalFuelStopAdvisorWarning);
    fct->Call(isolate->GetCurrentContext()->Global(), argc, argv);
}

void FuelStopAdvisorWrapper::SetFuelStopAdvisorWarningListener(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    v8::Isolate* isolate = args.GetIsolate();

    if (!args[0]->IsFunction()) {
        isolate->ThrowException(
        v8::Exception::TypeError(v8::String::NewFromUtf8(isolate,"Requires a function as parameter"))
        );
    }
    v8::Local<v8::Function> fct = v8::Local<v8::Function>::Cast(args[0]);
    v8::Persistent<v8::Function> persfct(isolate,fct);
    signalFuelStopAdvisorWarning.Reset(isolate,persfct);;

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Boolean::New(isolate, v8::True) );

    args.GetReturnValue().Set(ret);
}

v8::Persistent<v8::Function> FuelStopAdvisorWrapper::signalTripDataResetted;

void FuelStopAdvisorWrapper::TripDataResetted(const uint8_t& number)
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    v8::HandleScope handleScope(isolate);
    const unsigned argc = 1;
    v8::Local<v8::Value> argv[argc];

    argv[0]=v8::Local<v8::Value>::New(isolate,v8::Integer::New(isolate,number));

    v8::Local<v8::Function> fct= v8::Local<v8::Function>::New(isolate,signalTripDataResetted);
    fct->Call(isolate->GetCurrentContext()->Global(), argc, argv);
}

void FuelStopAdvisorWrapper::SetTripDataResettedListener(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    v8::Isolate* isolate = args.GetIsolate();

    if (!args[0]->IsFunction()) {
        isolate->ThrowException(
        v8::Exception::TypeError(v8::String::NewFromUtf8(isolate,"Requires a function as parameter"))
        );
    }

    v8::Local<v8::Function> fct = v8::Local<v8::Function>::Cast(args[0]);
    v8::Persistent<v8::Function> persfct(isolate,fct);
    signalTripDataResetted.Reset(isolate,persfct);;

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Boolean::New(isolate, v8::True) );

    args.GetReturnValue().Set(ret);
}

void FuelStopAdvisorWrapper::Init(v8::Local<v8::Object> target) {
    v8::Isolate* isolate = target->GetIsolate();

    // Prepare constructor template
    v8::Local<v8::FunctionTemplate> tpl = v8::FunctionTemplate::New(isolate, New);
    tpl->SetClassName(v8::String::NewFromUtf8(isolate, "FuelStopAdvisorWrapper"));
    tpl->InstanceTemplate()->SetInternalFieldCount(1);

    // Add all prototype methods, getters and setters here.
    NODE_SET_PROTOTYPE_METHOD(tpl, "getVersion", GetVersion);
    NODE_SET_PROTOTYPE_METHOD(tpl, "getInstantData", GetInstantData);
    NODE_SET_PROTOTYPE_METHOD(tpl, "setTripDataUpdatedListener", SetTripDataUpdatedListener);
    NODE_SET_PROTOTYPE_METHOD(tpl, "setFuelStopAdvisorWarningListener", SetFuelStopAdvisorWarningListener);
    NODE_SET_PROTOTYPE_METHOD(tpl, "setTripDataResettedListener", SetTripDataResettedListener);
    NODE_SET_PROTOTYPE_METHOD(tpl, "getEngineSpeed", GetEngineSpeed);
    NODE_SET_PROTOTYPE_METHOD(tpl, "getLevel", GetLevel);
    NODE_SET_PROTOTYPE_METHOD(tpl, "getInstantConsumption", GetInstantConsumption);
    NODE_SET_PROTOTYPE_METHOD(tpl, "getOdometer", GetOdometer);

    // This has to be last, otherwise the properties won't show up on the
    // object in JavaScript.
    constructor.Reset(isolate, tpl->GetFunction());
    target->Set(v8::String::NewFromUtf8(isolate, "FuelStopAdvisorWrapper"),
                 tpl->GetFunction());
}

FuelStopAdvisorWrapper::FuelStopAdvisorWrapper() {
}

FuelStopAdvisorWrapper::~FuelStopAdvisorWrapper() {
}

void FuelStopAdvisorWrapper::New(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();

    if (args.IsConstructCall()) {
      // Invoked as constructor: `new MyObject(...)`
//      double value = args[0]->IsUndefined() ? 0 : args[0]->NumberValue(); //no parameters
        FuelStopAdvisorWrapper* obj = new FuelStopAdvisorWrapper();
        obj->Wrap(args.This());
        args.GetReturnValue().Set(args.This());
        DemonstratorProxy* proxy = new DemonstratorProxy(obj);
        obj->mp_demonstratorProxy = proxy;
    } else { // not tested yet
      // Invoked as plain function `MyObject(...)`, turn into construct call.
      const int argc = 1;
      v8::Local<v8::Value> argv[argc] = { args[0] };
      v8::Local<v8::Context> context = isolate->GetCurrentContext();
      v8::Local<v8::Function> cons = v8::Local<v8::Function>::New(isolate, constructor);
      v8::Local<v8::Object> result = cons->NewInstance(context, argc, argv).ToLocalChecked();
      args.GetReturnValue().Set(result);
    }
}

void FuelStopAdvisorWrapper::NewInstance(const v8::FunctionCallbackInfo<v8::Value>& args) {
  v8::Isolate* isolate = args.GetIsolate();

  const unsigned argc = 1;
  v8::Local<v8::Value> argv[argc] = { args[0] };
  v8::Local<v8::Function> cons = v8::Local<v8::Function>::New(isolate, constructor);
  v8::Local<v8::Context> context = isolate->GetCurrentContext();
  v8::Local<v8::Object> instance =
      cons->NewInstance(context, argc, argv).ToLocalChecked();

  args.GetReturnValue().Set(instance);
}

void FuelStopAdvisorWrapper::GetVersion(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();

    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    ::DBus::Struct< uint16_t, uint16_t, uint16_t, std::string > DBus_version = obj->mp_demonstratorProxy->mp_fuelStopAdvisorProxy->GetVersion();

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Int32::New(isolate,DBus_version._1) );
    ret->Set( 1, v8::Int32::New(isolate,DBus_version._2) );
    ret->Set( 2, v8::Int32::New(isolate,DBus_version._3) );
    ret->Set( 3, v8::String::NewFromUtf8(isolate,DBus_version._4.c_str()) );

    args.GetReturnValue().Set(ret);
}

void FuelStopAdvisorWrapper::GetInstantData(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();
    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    std::map< uint16_t, ::DBus::Variant > instant_data = obj->mp_demonstratorProxy->mp_fuelStopAdvisorProxy->GetInstantData();


    v8::Local<v8::Array> ret = v8::Array::New(isolate);

    for (std::map< uint16_t, ::DBus::Variant >::iterator iter = instant_data.begin(); iter != instant_data.end(); iter++) {
        v8::Local<v8::Object> data = v8::Object::New(isolate);
        ::DBus::Variant value = iter->second;
        data->Set(v8::String::NewFromUtf8(isolate,"key"), v8::Uint32::New(isolate,iter->first));
        switch (iter->first) {
        case GENIVI_FUELSTOPADVISOR_FUEL_LEVEL:
            data->Set(v8::String::NewFromUtf8(isolate,"value"), v8::Uint32::New(isolate,value.reader().get_uint16()));
            break;
        case GENIVI_FUELSTOPADVISOR_INSTANT_FUEL_CONSUMPTION_PER_DISTANCE:
            data->Set(v8::String::NewFromUtf8(isolate,"value"), v8::Uint32::New(isolate,value.reader().get_uint16()));
            break;
        case GENIVI_FUELSTOPADVISOR_TANK_DISTANCE:
            data->Set(v8::String::NewFromUtf8(isolate,"value"), v8::Uint32::New(isolate,value.reader().get_uint16()));
            break;
        case GENIVI_FUELSTOPADVISOR_ENHANCED_TANK_DISTANCE:
            data->Set(v8::String::NewFromUtf8(isolate,"value"), v8::Uint32::New(isolate,value.reader().get_uint16()));
            break;
        default:
            break;
        }
        ret->Set(ret->Length(), data);
    }

    args.GetReturnValue().Set(ret);
}

void FuelStopAdvisorWrapper::GetEngineSpeed(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();

    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    DBus::Variant variant = obj->mp_demonstratorProxy->mp_managerProxy->GetSpeed();
    DBus::MessageIter it = variant.reader();
    uint16_t engineSpeed;
    it >> engineSpeed;

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Uint32::New(isolate, engineSpeed) );

    args.GetReturnValue().Set(ret);
}

void FuelStopAdvisorWrapper::GetLevel(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();

    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    DBus::Variant variant = obj->mp_demonstratorProxy->mp_managerProxy->GetLevel();
    DBus::MessageIter it = variant.reader();
    uint16_t level;
    it >> level;

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Uint32::New(isolate, level) );

    args.GetReturnValue().Set(ret);
}

void FuelStopAdvisorWrapper::GetInstantConsumption(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();

    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    DBus::Variant variant = obj->mp_demonstratorProxy->mp_managerProxy->GetInstantConsumption();
    DBus::MessageIter it = variant.reader();
    uint32_t consumption;
    it >> consumption;

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Uint32::New(isolate,consumption) );
    printf("GetInstantConsumption\n");

    args.GetReturnValue().Set(ret);
}

void FuelStopAdvisorWrapper::GetOdometer(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();

    // Retrieves the pointer to the wrapped object instance.
    FuelStopAdvisorWrapper* obj = ObjectWrap::Unwrap<FuelStopAdvisorWrapper>(args.This());

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    printf("GetOdometer\n");

    args.GetReturnValue().Set(ret);
}



void RegisterModule(v8::Handle<v8::Object> target) {
    FuelStopAdvisorWrapper::Init(target);
}

NODE_MODULE(FuelStopAdvisorWrapper, RegisterModule)
