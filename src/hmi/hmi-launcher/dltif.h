/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2017, PSA GROUP
*
* \file dltif.h
*
* \brief This file is part of the FSA HMI.
*
* \author Philippe COLLIOT <philippe.colliot@mpsa.com>
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
#include <QtDBus>

#include <QObject>
#include <log.h>

class DLTIf:public QQuickItem {
    Q_OBJECT Q_PROPERTY(QString name READ name WRITE setName)
public:
    DLTIf(QQuickItem * parent = 0);
    ~DLTIf();

    QString name() const;
    void setName(const QString & name);

    Q_INVOKABLE void log_info_msg(QString);

private:
    QString m_name;
};

