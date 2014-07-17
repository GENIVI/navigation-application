/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file dbusifsignal.h
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
#include <QtDBus/QtDBus>

class DBusIfSignal:public QQuickItem, protected QDBusContext {
	Q_OBJECT
      public:
	DBusIfSignal(QString service, QString path, QString interface, QString name, QObject *obj, QString slot)
	{
		m_service=service;
		m_path=path;
		m_interface=interface;
		m_name=name;
		m_obj=obj;
		m_slot=slot;	
		QDBusConnection::sessionBus().connect(service, path, interface, name, this, SLOT(signal()));
	}
	~DBusIfSignal()
	{
		QDBusConnection::sessionBus().disconnect(m_service, m_path, m_interface, m_name, this, SLOT(signal()));
	}
	QString m_service;
	QString m_path;
	QString m_interface;
	QString m_name;
	QObject *m_obj;
	QString m_slot;
      public slots:
	void signal();
};
