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

#include "PositioningProxy.hpp"
#include "../PositioningEnhancedPositionWrapper.hpp"

using namespace v8;
using namespace std;

static DBus::Glib::BusDispatcher *dispatcher;
static DBus::Connection *connection;

PositioningEnhancedPositionProxy::PositioningEnhancedPositionProxy(DBus::Connection &connection, PositioningProxy *positioningProxy)
    :    DBus::ObjectProxy(connection,
                           "/org/genivi/positioning/EnhancedPosition",
                           "org.genivi.positioning.EnhancedPosition")
{
    mp_positioningProxy = positioningProxy;
}

void PositioningEnhancedPositionProxy::PositionUpdate(const uint64_t& changedValues)
{
    mp_positioningProxy->PositionUpdate(changedValues);
}

PositioningProxy::PositioningProxy(PositioningEnhancedPositionWrapper *positioningEnhancedPositionWrapper)
{
    dispatcher = new DBus::Glib::BusDispatcher();
    DBus::default_dispatcher = dispatcher;
    dispatcher->attach(NULL);
    connection = new DBus::Connection(DBus::Connection::SessionBus());
    connection->setup(dispatcher);
    mp_positioningEnhancedPositionWrapper = positioningEnhancedPositionWrapper;
    mp_enhancedPositionProxy = new PositioningEnhancedPositionProxy(*connection,this);
}

PositioningProxy::~PositioningProxy()
{
    delete mp_enhancedPositionProxy;
    delete connection;
    delete dispatcher;
}

void PositioningProxy::PositionUpdate(const uint64_t& changedValues)
{
    mp_positioningEnhancedPositionWrapper->PositionUpdate(changedValues);
}
