/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file wheelareaplugin.h
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
#ifndef WHEELAREAPLUGIN_H
#define WHEELAREAPLUGIN_H

#include <QtDeclarative/qdeclarativeextensionplugin.h>

class WheelAreaPlugin:public QDeclarativeExtensionPlugin {
      Q_OBJECT public:
    Q_PLUGIN_METADATA(IID "Wheel area plugin" FILE "wheelareaplugin.json")
    void registerTypes(const char *uri);
};

#endif
