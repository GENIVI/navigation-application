/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file wheelareaplugin.cpp
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
#include "wheelareaplugin.h"
#include "wheelarea.h"
#include <QtQuick/qquickitem.h>

void
WheelAreaPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("LBSPlugin"));
    qmlRegisterType<WheelArea>(uri, 1, 0, "WheelArea");
}
