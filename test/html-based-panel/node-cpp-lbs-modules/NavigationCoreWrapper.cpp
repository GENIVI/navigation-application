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


v8::Persistent<v8::FunctionTemplate> NavigationCoreWrapper::constructor;

v8::Persistent<v8::Function> NavigationCoreWrapper::signalGuidanceStatusChanged;
v8::Persistent<v8::Function> NavigationCoreWrapper::signalSimulationStatusChanged;

void NavigationCoreWrapper::GuidanceStatusChanged(const int32_t& guidanceStatus, const uint32_t& routeHandle)
{
    v8::HandleScope scope();

    const unsigned argc = 2;
    v8::Local<v8::Value> argv[argc];

    argv[0]=v8::Local<v8::Value>::New(v8::Int32::New(guidanceStatus));
    argv[1]=v8::Local<v8::Value>::New(v8::Uint32::New(routeHandle));

    v8::Persistent<v8::Function> fct = static_cast<v8::Function*>(*signalGuidanceStatusChanged);
    fct->Call(v8::Context::GetCurrent()->Global(), argc, argv);
}

v8::Handle<v8::Value> NavigationCoreWrapper::SetGuidanceStatusChangedListener(const v8::Arguments& args)
{
    v8::HandleScope scope; //to properly clean up v8 handles

    if (!args[0]->IsFunction()) {
        return v8::ThrowException(
        v8::Exception::TypeError(v8::String::New("Requires a function as parameter"))
        );
    }

    signalGuidanceStatusChanged = v8::Persistent<v8::Function>::New(v8::Handle<v8::Function>::Cast(args[0]));

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Boolean::New(signalGuidanceStatusChanged->IsFunction()) );

    return scope.Close(ret);
}

void NavigationCoreWrapper::SimulationStatusChanged(const int32_t& simulationStatus)
{
    v8::HandleScope scope();

    const unsigned argc = 1;
    v8::Local<v8::Value> argv[argc];

    argv[0]=v8::Local<v8::Value>::New(v8::Int32::New(simulationStatus));

    v8::Persistent<v8::Function> fct = static_cast<v8::Function*>(*signalSimulationStatusChanged);
    fct->Call(v8::Context::GetCurrent()->Global(), argc, argv);
}

v8::Handle<v8::Value> NavigationCoreWrapper::SetSimulationStatusChangedListener(const v8::Arguments& args)
{
    v8::HandleScope scope; //to properly clean up v8 handles

    if (!args[0]->IsFunction()) {
        return v8::ThrowException(
        v8::Exception::TypeError(v8::String::New("Requires a function as parameter"))
        );
    }

    signalSimulationStatusChanged = v8::Persistent<v8::Function>::New(v8::Handle<v8::Function>::Cast(args[0]));

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Boolean::New(signalSimulationStatusChanged->IsFunction()) );

    return scope.Close(ret);
}

void NavigationCoreWrapper::Init(v8::Handle<v8::Object> target) {
    v8::HandleScope scope;

    v8::Local<v8::FunctionTemplate> tpl = v8::FunctionTemplate::New(New);
    v8::Local<v8::String> name = v8::String::NewSymbol("NavigationCoreWrapper");

    constructor = v8::Persistent<v8::FunctionTemplate>::New(tpl);
    // ObjectWrap uses the first internal field to store the wrapped pointer.
    constructor->InstanceTemplate()->SetInternalFieldCount(1);
    constructor->SetClassName(name);

    // Add all prototype methods, getters and setters here.
    NODE_SET_PROTOTYPE_METHOD(constructor, "setGuidanceStatusChangedListener", SetGuidanceStatusChangedListener);
    NODE_SET_PROTOTYPE_METHOD(constructor, "getGuidanceStatus", GetGuidanceStatus);
    NODE_SET_PROTOTYPE_METHOD(constructor, "setSimulationStatusChangedListener", SetSimulationStatusChangedListener);
    NODE_SET_PROTOTYPE_METHOD(constructor, "getSimulationStatus", GetSimulationStatus);
    NODE_SET_PROTOTYPE_METHOD(constructor, "getPosition", GetPosition);

    // This has to be last, otherwise the properties won't show up on the
    // object in JavaScript.
    target->Set(name, constructor->GetFunction());
}

NavigationCoreWrapper::NavigationCoreWrapper() {
}

NavigationCoreWrapper::~NavigationCoreWrapper() {
}

v8::Handle<v8::Value> NavigationCoreWrapper::New(const v8::Arguments& args) {
    v8::HandleScope scope;

    if (!args.IsConstructCall()) {
        return v8::ThrowException(v8::Exception::TypeError(
            v8::String::New("Use the new operator to create instances of this object."))
        );
    }
    // Creates a new instance object of this type and wraps it.
    NavigationCoreWrapper* obj = new NavigationCoreWrapper();

    NavigationCoreProxy* proxy = new NavigationCoreProxy(obj);

    obj->mp_navigationCoreProxy = proxy;
    obj->Wrap(args.This());

    return args.This();
}

void RegisterModule(v8::Handle<v8::Object> target) {
    NavigationCoreWrapper::Init(target);
}

v8::Handle<v8::Value> NavigationCoreWrapper::GetGuidanceStatus(const v8::Arguments& args)
{
    v8::HandleScope scope; //to properly clean up v8 handles

    // Retrieves the pointer to the wrapped object instance.
    NavigationCoreWrapper* obj = ObjectWrap::Unwrap<NavigationCoreWrapper>(args.This());
    int32_t guidanceStatus;
    uint32_t routeHandle;
    obj->mp_navigationCoreProxy->mp_navigationCoreGuidanceProxy->GetGuidanceStatus(guidanceStatus,routeHandle);

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Int32::New(guidanceStatus) );
    ret->Set( 1, v8::Uint32::New(routeHandle) );

    return scope.Close(ret);

}

v8::Handle<v8::Value> NavigationCoreWrapper::GetSimulationStatus(const v8::Arguments& args)
{
    v8::HandleScope scope; //to properly clean up v8 handles

    // Retrieves the pointer to the wrapped object instance.
    NavigationCoreWrapper* obj = ObjectWrap::Unwrap<NavigationCoreWrapper>(args.This());
    int32_t simulationStatus;
    simulationStatus = obj->mp_navigationCoreProxy->mp_navigationCoreMapMatchedPositionProxy->GetSimulationStatus();

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Int32::New(simulationStatus) );

    return scope.Close(ret);

}

v8::Handle<v8::Value> NavigationCoreWrapper::GetPosition(const v8::Arguments& args)
{
    v8::HandleScope scope; //to properly clean up v8 handles
    std::vector< int32_t > valuesToReturn;
    std::map< int32_t, ::DBus::Struct< uint8_t, ::DBus::Variant > > position;

    if (args.Length() < 1) {
        return v8::ThrowException(
        v8::Exception::TypeError(v8::String::New("getPosition requires at least 1 argument"))
        );
    }

    if (args[0]->IsArray()) {
        v8::Handle<v8::Array> array = v8::Handle<v8::Array>::Cast(args[0]);
        for(uint32_t i=0;i<array->Length();i++)
        {
           v8::Handle<v8::Value> value = v8::Handle<v8::Object>::Cast(array->Get(i));
           valuesToReturn.push_back(value->ToInt32()->Int32Value());
        }
    } else {
        return v8::ThrowException(
        v8::Exception::TypeError(v8::String::New("getPosition requires an array as argument"))
        );
    }

    // Retrieves the pointer to the wrapped object instance.
    NavigationCoreWrapper* obj = ObjectWrap::Unwrap<NavigationCoreWrapper>(args.This());
    position = obj->mp_navigationCoreProxy->mp_navigationCoreMapMatchedPositionProxy->GetPosition(valuesToReturn);

    v8::Local<v8::Array> ret = v8::Array::New();

    for (std::map< int32_t, ::DBus::Struct< uint8_t, ::DBus::Variant > >::iterator iter = position.begin(); iter != position.end(); iter++) {
        v8::Local<v8::Object> data = v8::Object::New();
        ::DBus::Struct< uint8_t, ::DBus::Variant > value;
        data->Set(v8::String::New("key"), v8::Int32::New(iter->first));
        value = iter->second;
        switch (iter->first) {
            case GENIVI_NAVIGATIONCORE_LATITUDE:
            case GENIVI_NAVIGATIONCORE_LONGITUDE:
            case GENIVI_NAVIGATIONCORE_ALTITUDE:
            case GENIVI_NAVIGATIONCORE_SPEED:
            case GENIVI_NAVIGATIONCORE_HEADING:
            default:
                data->Set(v8::String::New("value"), v8::Number::New(value._2));
                break;
        }
        ret->Set(ret->Length(), data);
    }

    return scope.Close(ret);
}

NODE_MODULE(NavigationCoreWrapper, RegisterModule);
