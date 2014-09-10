/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file preference.h
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
#include <QtQuick/qquickitem.h>
#include <QObject>

class Preference : public QObject
{
    Q_OBJECT
    Q_PROPERTY(unsigned int source READ source WRITE setSource)
    Q_PROPERTY(unsigned int mode READ mode WRITE setMode)
public:
    Preference(QObject *parent = 0);

    unsigned int source() const;
    void setSource(const unsigned int &source);

    unsigned int mode() const;
    void setMode(const unsigned int &mode);

private:
    unsigned int m_source;
    unsigned int m_mode;
};

QML_DECLARE_TYPE(Preference)
