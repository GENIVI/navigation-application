/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2017, PSA Group
*
* \file settings.h
*
* \brief This file is part of the FSA HMI.
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
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
#ifndef INCLUDE_SETTINGS
#define INCLUDE_SETTINGS

#include <QSettings>
#include <QCoreApplication>

class Settings:public QSettings
{
Q_OBJECT

public:
explicit Settings(QObject *parent = 0) : QSettings(QSettings::UserScope,
                                                   QCoreApplication::instance()->organizationName(),
                                                   QCoreApplication::instance()->applicationName(),
                                                   parent) {}

Q_INVOKABLE inline void setValue(const QString &key, const QVariant &value) { QSettings::setValue(key, value); }
Q_INVOKABLE inline QVariant getValue(const QString &key, const QVariant &defaultValue = QVariant()) const { return QSettings::value(key, defaultValue); }

};
Q_DECLARE_METATYPE(Settings*)

#endif
