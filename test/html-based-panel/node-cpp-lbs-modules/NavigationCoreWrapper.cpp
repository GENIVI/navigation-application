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

#include "NavigationCoreWrapper.hpp"


v8::Persistent<v8::Function> NavigationCoreWrapper::constructor;

v8::Persistent<v8::Function> NavigationCoreWrapper::signalGuidanceStatusChanged;
v8::Persistent<v8::Function> NavigationCoreWrapper::signalSimulationStatusChanged;

void NavigationCoreWrapper::GuidanceStatusChanged(const int32_t& guidanceStatus, const uint32_t& routeHandle)
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();

    const unsigned argc = 2;
    v8::Local<v8::Value> argv[argc];

    argv[0]=v8::Local<v8::Value>::New(isolate,v8::Int32::New(isolate,guidanceStatus));
    argv[1]=v8::Local<v8::Value>::New(isolate,v8::Uint32::New(isolate,routeHandle));

    v8::Local<v8::Function> fct;
    fct.New(isolate,signalGuidanceStatusChanged);
    fct->Call(isolate->GetCurrentContext()->Global(), argc, argv);
}

void NavigationCoreWrapper::SetGuidanceStatusChangedListener(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    v8::Isolate* isolate = args.GetIsolate();

    if (!args[0]->IsFunction()) {
        isolate->ThrowException(
        v8::Exception::TypeError(v8::String::NewFromUtf8(isolate,"Requires a function as parameter"))
        );
    }
    v8::Local<v8::Function> fct = v8::Local<v8::Function>::Cast(args[0]);
    v8::Persistent<v8::Function> persfct(isolate,fct);
    signalGuidanceStatusChanged.Reset(isolate,persfct);;

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Boolean::New(isolate, v8::True) );

    args.GetReturnValue().Set(ret);
}

void NavigationCoreWrapper::SimulationStatusChanged(const int32_t& simulationStatus)
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();

    const unsigned argc = 1;
    v8::Local<v8::Value> argv[argc];

    argv[0]=v8::Local<v8::Value>::New(isolate,v8::Int32::New(isolate,simulationStatus));

    v8::Local<v8::Function> fct;
    fct.New(isolate,signalSimulationStatusChanged);
    fct->Call(isolate->GetCurrentContext()->Global(), argc, argv);
}

void NavigationCoreWrapper::SetSimulationStatusChangedListener(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    v8::Isolate* isolate = args.GetIsolate();

    if (!args[0]->IsFunction()) {
        isolate->ThrowException(
        v8::Exception::TypeError(v8::String::NewFromUtf8(isolate,"Requires a function as parameter"))
        );
    }
    v8::Local<v8::Function> fct = v8::Local<v8::Function>::Cast(args[0]);
    v8::Persistent<v8::Function> persfct(isolate,fct);
    signalSimulationStatusChanged.Reset(isolate,persfct);;

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Boolean::New(isolate, v8::True) );

    args.GetReturnValue().Set(ret);
}

void NavigationCoreWrapper::Init(v8::Local<v8::Object> target) {
    v8::Isolate* isolate = target->GetIsolate();

    // Prepare constructor template
    v8::Local<v8::FunctionTemplate> tpl = v8::FunctionTemplate::New(isolate, New);
    tpl->SetClassName(v8::String::NewFromUtf8(isolate, "NavigationCoreWrapper"));
    tpl->InstanceTemplate()->SetInternalFieldCount(1);

    // Add all prototype methods, getters and setters here.
    NODE_SET_PROTOTYPE_METHOD(tpl, "setGuidanceStatusChangedListener", SetGuidanceStatusChangedListener);
    NODE_SET_PROTOTYPE_METHOD(tpl, "getGuidanceStatus", GetGuidanceStatus);
    NODE_SET_PROTOTYPE_METHOD(tpl, "setSimulationStatusChangedListener", SetSimulationStatusChangedListener);
    NODE_SET_PROTOTYPE_METHOD(tpl, "getSimulationStatus", GetSimulationStatus);
    NODE_SET_PROTOTYPE_METHOD(tpl, "getPosition", GetPosition);

    // This has to be last, otherwise the properties won't show up on the
    // object in JavaScript.
    constructor.Reset(isolate, tpl->GetFunction());
    target->Set(v8::String::NewFromUtf8(isolate, "NavigationCoreWrapper"),
                 tpl->GetFunction());
}

NavigationCoreWrapper::NavigationCoreWrapper() {
}

NavigationCoreWrapper::~NavigationCoreWrapper() {
}

void NavigationCoreWrapper::New(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();

    if (args.IsConstructCall()) {
      // Invoked as constructor: `new MyObject(...)`
//      double value = args[0]->IsUndefined() ? 0 : args[0]->NumberValue(); //no parameters
        NavigationCoreWrapper* obj = new NavigationCoreWrapper();
        obj->Wrap(args.This());
        args.GetReturnValue().Set(args.This());

        NavigationCoreProxy* proxy = new NavigationCoreProxy(obj);
        obj->mp_navigationCoreProxy = proxy;
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

void NavigationCoreWrapper::NewInstance(const v8::FunctionCallbackInfo<v8::Value>& args) {
  v8::Isolate* isolate = args.GetIsolate();

  const unsigned argc = 1;
  v8::Local<v8::Value> argv[argc] = { args[0] };
  v8::Local<v8::Function> cons = v8::Local<v8::Function>::New(isolate, constructor);
  v8::Local<v8::Context> context = isolate->GetCurrentContext();
  v8::Local<v8::Object> instance =
      cons->NewInstance(context, argc, argv).ToLocalChecked();

  args.GetReturnValue().Set(instance);
}

void RegisterModule(v8::Handle<v8::Object> target) {
    NavigationCoreWrapper::Init(target);
}

void NavigationCoreWrapper::GetGuidanceStatus(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    v8::Isolate* isolate = args.GetIsolate();

    // Retrieves the pointer to the wrapped object instance.
    NavigationCoreWrapper* obj = ObjectWrap::Unwrap<NavigationCoreWrapper>(args.This());
    int32_t guidanceStatus;
    uint32_t routeHandle;
    obj->mp_navigationCoreProxy->mp_navigationCoreGuidanceProxy->GetGuidanceStatus(guidanceStatus,routeHandle);

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Int32::New(isolate,guidanceStatus) );
    ret->Set( 1, v8::Uint32::New(isolate,routeHandle) );

    args.GetReturnValue().Set(ret);

}

void NavigationCoreWrapper::GetSimulationStatus(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    v8::Isolate* isolate = args.GetIsolate();

    // Retrieves the pointer to the wrapped object instance.
    NavigationCoreWrapper* obj = ObjectWrap::Unwrap<NavigationCoreWrapper>(args.This());
    int32_t simulationStatus;
    simulationStatus = obj->mp_navigationCoreProxy->mp_navigationCoreMapMatchedPositionProxy->GetSimulationStatus();

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Int32::New(isolate,simulationStatus) );

    args.GetReturnValue().Set(ret);

}

void NavigationCoreWrapper::GetPosition(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    v8::Isolate* isolate = args.GetIsolate();
    std::vector< int32_t > valuesToReturn;
    std::map< int32_t, ::DBus::Struct< uint8_t, ::DBus::Variant > > position;

    if (args.Length() < 1) {
        isolate->ThrowException(
        v8::Exception::TypeError(v8::String::NewFromUtf8(isolate,"getPosition requires at least 1 argument"))
        );
    }

    if (args[0]->IsArray()) {
        v8::Local<v8::Array> array = v8::Local<v8::Array>::Cast(args[0]);
        for(uint32_t i=0;i<array->Length();i++)
        {
           v8::Local<v8::Value> value = v8::Local<v8::Object>::Cast(array->Get(i));
           valuesToReturn.push_back(value->ToInt32()->Int32Value());
        }
    } else {
        isolate->ThrowException(
        v8::Exception::TypeError(v8::String::NewFromUtf8(isolate,"getPosition requires an array as argument"))
        );
    }

    // Retrieves the pointer to the wrapped object instance.
    NavigationCoreWrapper* obj = ObjectWrap::Unwrap<NavigationCoreWrapper>(args.This());
    position = obj->mp_navigationCoreProxy->mp_navigationCoreMapMatchedPositionProxy->GetPosition(valuesToReturn);

    v8::Local<v8::Array> ret = v8::Array::New(isolate);

    for (std::map< int32_t, ::DBus::Struct< uint8_t, ::DBus::Variant > >::iterator iter = position.begin(); iter != position.end(); iter++) {
        v8::Local<v8::Object> data = v8::Object::New(isolate);
        ::DBus::Struct< uint8_t, ::DBus::Variant > value;
        data->Set(v8::String::NewFromUtf8(isolate,"key"), v8::Int32::New(isolate,iter->first));
        value = iter->second;
        switch (iter->first) {
            case GENIVI_NAVIGATIONCORE_LATITUDE:
            case GENIVI_NAVIGATIONCORE_LONGITUDE:
            case GENIVI_NAVIGATIONCORE_ALTITUDE:
            case GENIVI_NAVIGATIONCORE_SPEED:
            case GENIVI_NAVIGATIONCORE_HEADING:
            default:
                data->Set(v8::String::NewFromUtf8(isolate,"value"), v8::Number::New(isolate,value._2));
                break;
        }
        ret->Set(ret->Length(), data);
    }

    args.GetReturnValue().Set(ret);
}

NODE_MODULE(NavigationCoreWrapper, RegisterModule)
