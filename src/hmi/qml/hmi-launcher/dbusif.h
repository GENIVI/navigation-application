/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file dbusif.h
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
#include <QtQuick/qquickitem.h>
#include <QtDBus>

#include <QObject>

class DBusIf:public QQuickItem {
	Q_OBJECT Q_PROPERTY(QString name READ name WRITE setName)
      public:
    DBusIf(QQuickItem * parent = 0);

	QString name() const;
	void setName(const QString & name);

	Q_INVOKABLE void signal(QString, QString, QString, QVariant);
	Q_INVOKABLE QVariant message(QString, QString, QString, QString, QVariant);
	Q_INVOKABLE QObject *connect(QString, QString, QString, QString, QObject *, QString);
	Q_INVOKABLE void quit(void);
	Q_INVOKABLE int pid(void);
      private:
	QString m_name;
};


