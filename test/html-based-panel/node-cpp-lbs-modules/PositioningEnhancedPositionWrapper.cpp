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


v8::Persistent<v8::Function> PositioningEnhancedPositionWrapper::constructor;

v8::Persistent<v8::Function> PositioningEnhancedPositionWrapper::signalPositionUpdate;
void PositioningEnhancedPositionWrapper::PositionUpdate(const uint64_t& changedValues) {
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    v8::HandleScope handleScope(isolate);
    printf("PositionUpdate\n");

    const unsigned argc = 2;
    uint64to32 data;
    data.full = changedValues;
    v8::Local<v8::Value> argv[argc];
    argv[0] = v8::Local<v8::Value>::New(isolate,v8::Uint32::New(isolate,data.p.high));
    argv[1] = v8::Local<v8::Value>::New(isolate,v8::Uint32::New(isolate,data.p.low));
    v8::Local<v8::Function> fct= v8::Local<v8::Function>::New(isolate,signalPositionUpdate);
    fct->Call(isolate->GetCurrentContext()->Global(), argc, argv);
}
void PositioningEnhancedPositionWrapper::SetPositionUpdateListener(const v8::FunctionCallbackInfo<v8::Value> &args)
{
    v8::Isolate* isolate = args.GetIsolate();

    if (!args[0]->IsFunction()) {
        isolate->ThrowException(
        v8::Exception::TypeError(v8::String::NewFromUtf8(isolate,"Requires a function as parameter"))
        );
    }
    v8::Local<v8::Function> fct = v8::Local<v8::Function>::Cast(args[0]);
    v8::Persistent<v8::Function> persfct(isolate,fct);
    signalPositionUpdate.Reset(isolate,persfct);;

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Boolean::New(isolate, v8::True) );

    args.GetReturnValue().Set(ret);
}

void PositioningEnhancedPositionWrapper::Init(v8::Local<v8::Object> target) {
    v8::Isolate* isolate = target->GetIsolate();

    // Prepare constructor template
    v8::Local<v8::FunctionTemplate> tpl = v8::FunctionTemplate::New(isolate, New);
    tpl->SetClassName(v8::String::NewFromUtf8(isolate, "PositioningEnhancedPositionWrapper"));
    tpl->InstanceTemplate()->SetInternalFieldCount(1);

    // Add all prototype methods, getters and setters here.
    NODE_SET_PROTOTYPE_METHOD(tpl, "getVersion", GetVersion);
    NODE_SET_PROTOTYPE_METHOD(tpl, "getPositionInfo", GetPositionInfo);
    NODE_SET_PROTOTYPE_METHOD(tpl, "setPositionUpdateListener", SetPositionUpdateListener);

    // This has to be last, otherwise the properties won't show up on the
    // object in JavaScript.
    constructor.Reset(isolate, tpl->GetFunction());
    target->Set(v8::String::NewFromUtf8(isolate, "PositioningEnhancedPositionWrapper"),
                 tpl->GetFunction());
}

PositioningEnhancedPositionWrapper::PositioningEnhancedPositionWrapper() {
}

PositioningEnhancedPositionWrapper::~PositioningEnhancedPositionWrapper() {
}

void PositioningEnhancedPositionWrapper::New(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();

    if (args.IsConstructCall()) {
      // Invoked as constructor: `new MyObject(...)`
//      double value = args[0]->IsUndefined() ? 0 : args[0]->NumberValue(); //no parameters
    PositioningEnhancedPositionWrapper* obj = new PositioningEnhancedPositionWrapper();
    obj->Wrap(args.This());
    args.GetReturnValue().Set(args.This());

    PositioningProxy* proxy = new PositioningProxy(obj);
    obj->mp_positioningProxy = proxy;
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

void PositioningEnhancedPositionWrapper::NewInstance(const v8::FunctionCallbackInfo<v8::Value>& args) {
  v8::Isolate* isolate = args.GetIsolate();

  const unsigned argc = 1;
  v8::Local<v8::Value> argv[argc] = { args[0] };
  v8::Local<v8::Function> cons = v8::Local<v8::Function>::New(isolate, constructor);
  v8::Local<v8::Context> context = isolate->GetCurrentContext();
  v8::Local<v8::Object> instance =
      cons->NewInstance(context, argc, argv).ToLocalChecked();

  args.GetReturnValue().Set(instance);
}

void PositioningEnhancedPositionWrapper::GetVersion(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();

    // Retrieves the pointer to the wrapped object instance.
    PositioningEnhancedPositionWrapper* obj = ObjectWrap::Unwrap<PositioningEnhancedPositionWrapper>(args.This());

    ::DBus::Struct< uint16_t, uint16_t, uint16_t, std::string > DBus_version = obj->mp_positioningProxy->mp_enhancedPositionProxy->GetVersion();

    v8::Local<v8::Object> ret = v8::Object::New(isolate);
    ret->Set( 0, v8::Int32::New(isolate,DBus_version._1) );
    ret->Set( 1, v8::Int32::New(isolate,DBus_version._2) );
    ret->Set( 2, v8::Int32::New(isolate,DBus_version._3) );
    ret->Set( 3, v8::String::NewFromUtf8(isolate,DBus_version._4.c_str()) );

    args.GetReturnValue().Set(ret);
}

void PositioningEnhancedPositionWrapper::GetPositionInfo(const v8::FunctionCallbackInfo<v8::Value> &args) {
    v8::Isolate* isolate = args.GetIsolate();

    uint64to32 valuesToReturn;

    if (args.Length() < 1) {
        isolate->ThrowException(
        v8::Exception::TypeError(v8::String::NewFromUtf8(isolate,"getPositionInfo requires at least 1 argument"))
        );
    }

    if (args[0]->IsArray()) {
        v8::Local<v8::Array> array = v8::Local<v8::Array>::Cast(args[0]);
        v8::Local<v8::Value> msb = v8::Local<v8::Object>::Cast(array->Get(0));
        v8::Local<v8::Value> lsb = v8::Local<v8::Object>::Cast(array->Get(1));
        valuesToReturn.p.high = msb->ToInt32()->Int32Value();
        valuesToReturn.p.low = lsb->ToInt32()->Int32Value();
    } else {
        isolate->ThrowException(
        v8::Exception::TypeError(v8::String::NewFromUtf8(isolate,"getPositionInfo requires an array as argument"))
        );
    }

    // Retrieves the pointer to the wrapped object instance.
    PositioningEnhancedPositionWrapper* obj = ObjectWrap::Unwrap<PositioningEnhancedPositionWrapper>(args.This());
    uint64_t timestamp;
    std::map< uint64_t, ::DBus::Variant > position;
    obj->mp_positioningProxy->mp_enhancedPositionProxy->GetPositionInfo(valuesToReturn.full, timestamp, position);


    v8::Local<v8::Array> ret = v8::Array::New(isolate);

    v8::Local<v8::Object> tst = v8::Object::New(isolate);
    uint64to32 t;
    t.full = timestamp;
    tst->Set(v8::String::NewFromUtf8(isolate,"timestamp_msb"), v8::Uint32::New(isolate,t.p.high));
    tst->Set(v8::String::NewFromUtf8(isolate,"timestamp_lsb"), v8::Uint32::New(isolate,t.p.low));
    ret->Set(ret->Length(), tst);

    for (std::map< uint64_t, ::DBus::Variant >::iterator iter = position.begin(); iter != position.end(); iter++) {
        v8::Local<v8::Object> data = v8::Object::New(isolate);
        ::DBus::Variant value;
        uint64to32 key;
        value = iter->second;
        key.full = iter->first;
        data->Set(v8::String::NewFromUtf8(isolate,"key_msb"), v8::Uint32::New(isolate,key.p.high));
        data->Set(v8::String::NewFromUtf8(isolate,"key_lsb"), v8::Uint32::New(isolate,key.p.low));
        switch (iter->first) {
            case GENIVI_ENHANCEDPOSITIONSERVICE_LATITUDE:
            case GENIVI_ENHANCEDPOSITIONSERVICE_LONGITUDE:
            case GENIVI_ENHANCEDPOSITIONSERVICE_ALTITUDE:
            default:
                data->Set(v8::String::NewFromUtf8(isolate,"value"), v8::Number::New(isolate,value));
                break;
        }
        ret->Set(ret->Length(), data);
    }

    args.GetReturnValue().Set(ret);
}


void RegisterModule(v8::Handle<v8::Object> target) {
    PositioningEnhancedPositionWrapper::Init(target);
}

NODE_MODULE(PositioningEnhancedPositionWrapper, RegisterModule)
