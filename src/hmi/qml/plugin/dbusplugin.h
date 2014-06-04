/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file dbusplugin.h
*
* \brief This file is part of the FSA HMI.
*
* \author Martin Schaller <martin.schaller@it-schaller.de>
*
* \version 1.0
*
* This Source Code Form is subject to the terms of the
* Mozilla Public License (MPL), v. 2.0.
* If a copy of the MPL was not distributed with this file,
* You can obtain one at http://mozilla.org/MPL/2.0/.
*
* For further information see http://www.genivi.org/.
*
* List of changes:
* 
* <date>, <name>, <description of change>
*
* @licence end@
*/
#ifndef DBUSPLUGIN_H
#define DBUSPLUGIN_H

#include <QtDeclarative/qdeclarativeextensionplugin.h>

class DBusPlugin:public QDeclarativeExtensionPlugin {
      Q_OBJECT public:
    Q_PLUGIN_METADATA(IID "DBus plugin" FILE "dbusplugin.json")
    void registerTypes(const char *uri);
};

#endif
