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
#ifndef POSITIONINGPROXY_HPP
#define POSITIONINGPROXY_HPP

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

class PositioningProxy;
class PositioningEnhancedPositionProxy
        : public org::genivi::positioning::EnhancedPosition_proxy,
          public DBus::ObjectProxy
{
public:

    PositioningEnhancedPositionProxy(DBus::Connection &connection,PositioningProxy* positioningProxy);
    void PositionUpdate(const uint64_t& changedValues);

private:
    PositioningProxy* mp_positioningProxy;
};

class PositioningEnhancedPositionWrapper;
class PositioningProxy
{
public:
    PositioningProxy(PositioningEnhancedPositionWrapper* positioningEnhancedPositionWrapper);
    ~PositioningProxy();

    PositioningEnhancedPositionProxy* mp_enhancedPositionProxy;
    void PositionUpdate(const uint64_t& changedValues);

private:
    PositioningEnhancedPositionWrapper* mp_positioningEnhancedPositionWrapper;
};

#endif
