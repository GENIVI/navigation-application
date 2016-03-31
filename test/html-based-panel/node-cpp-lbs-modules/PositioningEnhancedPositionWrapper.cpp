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

#include "PositioningEnhancedPositionWrapper.hpp"

using namespace std;


v8::Persistent<v8::FunctionTemplate> PositioningEnhancedPositionWrapper::constructor;

v8::Persistent<v8::Function> PositioningEnhancedPositionWrapper::signalPositionUpdate;
void PositioningEnhancedPositionWrapper::PositionUpdate(const uint64_t& changedValues) {
    v8::HandleScope scope;

<<<<<<< HEAD
    const int argc = 2;
    uint64to32 data;
    data.full = changedValues;
    v8::Handle<v8::Value> argv[argc];
    argv[0] = v8::Local<v8::Value>::New(v8::Uint32::New(data.p.high));
    argv[1] = v8::Local<v8::Value>::New(v8::Uint32::New(data.p.low));
=======
    const unsigned argc = 2;
    uint64to32 data;
    data.full = changedValues;
    v8::Local<v8::Value> argv[argc];
    argv[0] = v8::Local<v8::Value>::New(v8::Uint32::New(data.p.high));
    argv[1] = v8::Local<v8::Value>::New(v8::Uint32::New(data.p.low));

>>>>>>> branch 'master' of ssh://git-genivi@git.projects.genivi.org/lbs/navigation-application.git
    v8::Persistent<v8::Function> fct = static_cast<v8::Function*>(*signalPositionUpdate);
    fct->Call(v8::Context::GetCurrent()->Global(), argc, argv);
}
v8::Handle<v8::Value> PositioningEnhancedPositionWrapper::SetPositionUpdateListener(const v8::Arguments& args)
{
    v8::HandleScope scope; //to properly clean up v8 handles

    if (!args[0]->IsFunction()) {
        return v8::ThrowException(
        v8::Exception::TypeError(v8::String::New("Requires a function as parameter"))
        );
    }

    signalPositionUpdate = v8::Persistent<v8::Function>::New(v8::Handle<v8::Function>::Cast(args[0]));

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Boolean::New(signalPositionUpdate->IsFunction()) );

    return scope.Close(ret);
}

void PositioningEnhancedPositionWrapper::Init(v8::Handle<v8::Object> target) {
    v8::HandleScope scope;

    v8::Local<v8::FunctionTemplate> tpl = v8::FunctionTemplate::New(New);
    v8::Local<v8::String> name = v8::String::NewSymbol("PositioningEnhancedPositionWrapper");

    constructor = v8::Persistent<v8::FunctionTemplate>::New(tpl);
    // ObjectWrap uses the first internal field to store the wrapped pointer.
    constructor->InstanceTemplate()->SetInternalFieldCount(1);
    constructor->SetClassName(name);

    // Add all prototype methods, getters and setters here.
    NODE_SET_PROTOTYPE_METHOD(constructor, "getVersion", GetVersion);
    NODE_SET_PROTOTYPE_METHOD(constructor, "getPositionInfo", GetPositionInfo);
    NODE_SET_PROTOTYPE_METHOD(constructor, "setPositionUpdateListener", SetPositionUpdateListener);

    // This has to be last, otherwise the properties won't show up on the
    // object in JavaScript.
    target->Set(name, constructor->GetFunction());
}

PositioningEnhancedPositionWrapper::PositioningEnhancedPositionWrapper() {
}

PositioningEnhancedPositionWrapper::~PositioningEnhancedPositionWrapper() {
}

v8::Handle<v8::Value> PositioningEnhancedPositionWrapper::New(const v8::Arguments& args) {
    v8::HandleScope scope;

    if (!args.IsConstructCall()) {
        return v8::ThrowException(v8::Exception::TypeError(
            v8::String::New("Use the new operator to create instances of this object."))
        );
    }

    // Creates a new instance object of this type and wraps it.
    PositioningEnhancedPositionWrapper* obj = new PositioningEnhancedPositionWrapper();

    PositioningProxy* proxy = new PositioningProxy(obj);
    obj->mp_positioningProxy = proxy;
    obj->Wrap(args.This());

    return args.This();
}

v8::Handle<v8::Value> PositioningEnhancedPositionWrapper::GetVersion(const v8::Arguments& args) {
    v8::HandleScope scope; //to properly clean up v8 handles

    // Retrieves the pointer to the wrapped object instance.
    PositioningEnhancedPositionWrapper* obj = ObjectWrap::Unwrap<PositioningEnhancedPositionWrapper>(args.This());

    ::DBus::Struct< uint16_t, uint16_t, uint16_t, std::string > DBus_version = obj->mp_positioningProxy->mp_enhancedPositionProxy->GetVersion();

    v8::Local<v8::Object> ret = v8::Object::New();
    ret->Set( 0, v8::Int32::New(DBus_version._1) );
    ret->Set( 1, v8::Int32::New(DBus_version._2) );
    ret->Set( 2, v8::Int32::New(DBus_version._3) );
    ret->Set( 3, v8::String::New(DBus_version._4.c_str()) );

    return scope.Close(ret);
}

v8::Handle<v8::Value> PositioningEnhancedPositionWrapper::GetPositionInfo(const v8::Arguments& args) {
    v8::HandleScope scope; //to properly clean up v8 handles

    // Retrieves the pointer to the wrapped object instance.
    PositioningEnhancedPositionWrapper* obj = ObjectWrap::Unwrap<PositioningEnhancedPositionWrapper>(args.This());
    uint64_t valuesToReturn=GENIVI_ENHANCEDPOSITIONSERVICE_LATITUDE | GENIVI_ENHANCEDPOSITIONSERVICE_LONGITUDE | GENIVI_ENHANCEDPOSITIONSERVICE_ALTITUDE;
    uint64_t timestamp;
    std::map< uint64_t, ::DBus::Variant > position;
    obj->mp_positioningProxy->mp_enhancedPositionProxy->GetPositionInfo(valuesToReturn, timestamp, position);


    v8::Local<v8::Array> ret = v8::Array::New();

    v8::Local<v8::Object> tst = v8::Object::New();
    uint64to32 t;
    t.full = timestamp;
    tst->Set(v8::String::New("timestamp_msb"), v8::Uint32::New(t.p.high));
    tst->Set(v8::String::New("timestamp_lsb"), v8::Uint32::New(t.p.low));
    ret->Set(ret->Length(), tst);

    for (std::map< uint64_t, ::DBus::Variant >::iterator iter = position.begin(); iter != position.end(); iter++) {
        v8::Local<v8::Object> data = v8::Object::New();
        ::DBus::Variant value;
        uint64to32 key;
        value = iter->second;
        key.full = iter->first;
        data->Set(v8::String::New("key_msb"), v8::Uint32::New(key.p.high));
        data->Set(v8::String::New("key_lsb"), v8::Uint32::New(key.p.low));
        switch (iter->first) {
            case GENIVI_ENHANCEDPOSITIONSERVICE_LATITUDE:
            case GENIVI_ENHANCEDPOSITIONSERVICE_LONGITUDE:
            case GENIVI_ENHANCEDPOSITIONSERVICE_ALTITUDE:
            default:
                data->Set(v8::String::New("value"), v8::Number::New(value));
                break;
        }
        ret->Set(ret->Length(), data);
    }

    return scope.Close(ret);
}


void RegisterModule(v8::Handle<v8::Object> target) {
    PositioningEnhancedPositionWrapper::Init(target);
}

NODE_MODULE(PositioningEnhancedPositionWrapper, RegisterModule);
