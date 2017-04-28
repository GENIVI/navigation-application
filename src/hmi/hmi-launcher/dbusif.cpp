/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file dbusif.cpp
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
#include "dbusif.h"
#include "dbusifsignal.h"
#include <sys/types.h>
#include <unistd.h>
#include <dbus/dbus.h>

DBusIf::DBusIf(QQuickItem * parent)
:  QQuickItem(parent)
{
}

QString
DBusIf::name() const
{
	return m_name;
}

void
DBusIf::setName(const QString & name)
{
	m_name = name;
}

void
 DBusIf::signal(QString path, QString interface, QString method,
		QVariant v)
{
	QDBusMessage msg = QDBusMessage::createSignal(path, interface, method);

    // unbox the QVariant-QJSValue to fix the Qt 5.4 QML -> C++ QVariant issues
    if (v.userType() == qMetaTypeId<QJSValue>()) {
        v = v.value<QJSValue>().toVariant();
    }

	if (v.type() == QVariant::List) {
		QVariantList l = v.value < QVariantList > ();
		for (int i = 0; i < l.size(); i++) {
			msg << l[i]; }
	} else
		msg << v;
	QDBusConnection::sessionBus().send(msg);
#if 0
	qDebug() << v;
#endif
}

static QVariant
dbus_from_qml(QVariant v)
{
	QVariantList l = v.value < QVariantList > ();

    if (l.size() != 2) {
		qDebug() << "Wrong Size" << v;
		throw("wrong array size");
	}
	QString type=l[0].toString();
	if (type == "int32") {
		return QVariant(l[1].toInt());
	} else if (type == "uint32" || type == "byte") {
		return QVariant(l[1].toUInt());
	} else if (type == "string") {
		return QVariant(l[1].toString());
	} else {
		qDebug() << "Unknown type" << type;
		throw("wrong type");
	}
}

static QList<QVariant>
dbus_list_from_qml_list(QVariant v)
{
    // unbox the QVariant-QJSValue to fix the Qt 5.4 QML -> C++ QVariant issues
    if (v.userType() == qMetaTypeId<QJSValue>()) {
        v = v.value<QJSValue>().toVariant();
    }

    if (v.type() != QVariant::List) {
		qDebug() << "Wrong Variant Type" << v;
		throw("wrong variant type");
	}
	QVariantList l = v.value < QVariantList > ();
	QList<QVariant> r;
	for (int i = 0; i < l.size(); i++) {
		r.append(dbus_from_qml(l[i]));
	}
	return r;
}

static QVariantList
qml_from_dbus(QVariant v)
{
	QVariantList r;
	const char *type=v.typeName();
	switch (v.type()) {
	case QVariant::UInt:
		r.append("uint32");
		r.append(v.toUInt());
		break;
	case QVariant::Int:
		r.append("int32");
		r.append(v.toInt());
		break;
	case QMetaType::UShort:
		r.append("uint16");
		r.append(v.toUInt());
		break;
	case QMetaType::UChar:
		r.append("uint8");
		r.append(v.toUInt());
		break;
	case QVariant::String:
		r.append("string");
		r.append(v.toString());
		break;
	case QVariant::Bool:
		r.append("bool");
		r.append(v.toBool());
		break;
	case QVariant::Double:
		r.append("double");
		r.append(v.toDouble());
		break;
	case QVariant::UserType:
		if (!strcmp(type,"QDBusArgument")) {
			const QDBusArgument arg=v.value < QDBusArgument>();
			QVariantList rl;
			switch(arg.currentType()) {
			case QDBusArgument::ArrayType:
				r.append("array");
				arg.beginArray();
				while (!arg.atEnd()) {
					rl.append(qml_from_dbus(arg.asVariant()));
				}
				r.append(QVariant(rl));
				break;
			case QDBusArgument::StructureType:
				r.append("structure");
				arg.beginStructure();
				while (!arg.atEnd()) {
					rl.append(qml_from_dbus(arg.asVariant()));
				}
				arg.endStructure();
				r.append(QVariant(rl));
				break;
			case QDBusArgument::MapType:
				r.append("map");
				arg.beginMap();
				while (!arg.atEnd()) {
					arg.beginMapEntry();
					rl.append(qml_from_dbus(arg.asVariant()));
					rl.append(qml_from_dbus(arg.asVariant()));
					arg.endMapEntry();
				}
				arg.endMap();
				r.append(QVariant(rl));
				break;
			case QDBusArgument::UnknownType:
				break;
			default:
				printf("Unknown type %d\n",arg.currentType());
				break;
			}
		} else if (!strcmp(type,"QDBusVariant")) {
			const QDBusVariant arg=v.value < QDBusVariant>();
			QVariantList rl;
			r.append("variant");
			rl.append(qml_from_dbus(arg.variant()));
			r.append(QVariant(rl));
		} else {
			printf("User type %s\n",v.typeName());
		}
		break;
	default:
		fprintf(stderr,"Unsupported Arg %s(%d)\n",type,v.type());
	}
	return r;
}

static QList<QVariant>
qml_list_from_dbus_list(QVariantList l)
{
	QVariantList r;

	for (int i = 0; i < l.size(); i++) {
		r.append(qml_from_dbus(l[i]));
	}
	return r;
}

static QVariantList
qml_from_dbus_iter(DBusMessageIter *iter)
{
	QVariantList r;
	int arg=dbus_message_iter_get_arg_type(iter);
	switch(arg) {
	case DBUS_TYPE_ARRAY:
		{
			DBusMessageIter sub;
			QVariantList a;
			dbus_message_iter_recurse(iter, &sub);
			const char *type="array";
			for (;;) {
				if (dbus_message_iter_get_arg_type(&sub) == DBUS_TYPE_DICT_ENTRY)
					type="map";
				a.append(qml_from_dbus_iter(&sub));
				if (!dbus_message_iter_has_next(&sub))
					break;
				dbus_message_iter_next(&sub);
			}	
			r.append(type);
			r.append(QVariant(a));
		}
		break;
	case DBUS_TYPE_DICT_ENTRY:
		{
			DBusMessageIter sub;
			dbus_message_iter_recurse(iter, &sub);
			for (;;) {
				r.append(qml_from_dbus_iter(&sub));
				if (!dbus_message_iter_has_next(&sub))
					break;
				dbus_message_iter_next(&sub);
			}	
		}
		break;
	case DBUS_TYPE_VARIANT:
		{
			DBusMessageIter sub;
			QVariantList a;
			dbus_message_iter_recurse(iter, &sub);
			for (;;) {
				a.append(qml_from_dbus_iter(&sub));
				if (!dbus_message_iter_has_next(&sub))
					break;
				dbus_message_iter_next(&sub);
			}	
			r.append("variant");
			r.append(QVariant(a));
		}
		break;
		break;
	case DBUS_TYPE_STRUCT:
		{
			DBusMessageIter sub;
			QVariantList a;
			dbus_message_iter_recurse(iter, &sub);
			for (;;) {
				a.append(qml_from_dbus_iter(&sub));
				if (!dbus_message_iter_has_next(&sub))
					break;
				dbus_message_iter_next(&sub);
			}	
			r.append("structure");
			r.append(QVariant(a));
		}
		break;
	case DBUS_TYPE_BOOLEAN:
		{
			dbus_bool_t v;
			r.append("boolean");
			dbus_message_iter_get_basic(iter, &v);
			r.append(v);
		}
		break;
	case DBUS_TYPE_INT16:
		{
			dbus_int16_t v;
			r.append("int16");
			dbus_message_iter_get_basic(iter, &v);
			r.append(v);
		}
		break;
	case DBUS_TYPE_INT32:
		{
			dbus_int32_t v;
			r.append("int32");
			dbus_message_iter_get_basic(iter, &v);
			r.append(v);
		}
		break;
	case DBUS_TYPE_BYTE:
		{
			unsigned char v;
			r.append("uint8");
			dbus_message_iter_get_basic(iter, &v);
			r.append(v);
		}
		break;
	case DBUS_TYPE_UINT32:
		{
			dbus_uint32_t v;
			r.append("uint32");
			dbus_message_iter_get_basic(iter, &v);
			r.append(v);
		}
		break;
	case DBUS_TYPE_UINT16:
		{
			dbus_uint16_t v;
			r.append("uint16");
			dbus_message_iter_get_basic(iter, &v);
			r.append(v);
		}
		break;
	case DBUS_TYPE_DOUBLE:
		{
			double v;
			r.append("double");
			dbus_message_iter_get_basic(iter, &v);
			r.append(v);
		}
		break;
	case DBUS_TYPE_STRING:
		{
			char *v;
			r.append("string");
			dbus_message_iter_get_basic(iter, &v);
			r.append(QString::fromUtf8(v));
		}
		break;
	case DBUS_TYPE_INVALID:
		break;
	default:
		fprintf(stderr,"Unsupported Arg %d(%c)\n",arg,(char)arg);
	}
	return r;
}

static QList<QVariant>
qml_list_from_dbus_message(DBusMessage *msg)
{
	DBusMessageIter iter;
	QVariantList r;
	dbus_message_iter_init(msg, &iter);
	for (;;) {
		r.append(qml_from_dbus_iter(&iter));
		if (!dbus_message_iter_has_next(&iter))
			break;
		dbus_message_iter_next(&iter);
	}
	// qDebug() << "Result" << r;
	return r;
}

static QString
signature_from_qml(QVariant t, QVariant v)
{
	
	QString type=t.toString();

	if (type == "double") {
		return QString(DBUS_TYPE_DOUBLE);
	} else if (type == "int32") {
		return QString(DBUS_TYPE_INT32);
    } else if (type == "uint8") {
        return QString(DBUS_TYPE_BYTE);
    } else if (type == "uint16") {
		return QString(DBUS_TYPE_UINT16);
	} else if (type == "uint32") {
		return QString(DBUS_TYPE_UINT32);
	} else if (type == "string") {
		return QString(DBUS_TYPE_STRING);
	} else if (type == "variant") {
		return QString(DBUS_TYPE_VARIANT);
    } else if (type == "structure") {
        //scan the structure to build the signature !
        QVariantList s=v.value <QVariantList>();
        QString signature = QString(DBUS_STRUCT_BEGIN_CHAR);
        if (s.size()%2) {
            qDebug() << "structure must have even number of elements, not " << s.size();
            throw("structure must have even number of elements");
        }
        else
        {
            for (int i = 0; i < s.size(); i+=2) {
                signature += signature_from_qml(s[i],s[i+1]);
            }
        }
        signature  += QString(DBUS_STRUCT_END_CHAR);
        return signature;
    } else if (type == "array") {
		QVariantList a=v.value <QVariantList>();
		return QString(DBUS_TYPE_ARRAY)+signature_from_qml(a[0],a[1]);
	} else if (type == "map") {
		QVariantList a=v.value <QVariantList>();
		return "a{"+signature_from_qml(a[0],a[1])+signature_from_qml(a[2],a[3])+"}";
	} else {
		qDebug() << "signature:Unknown type" << type;
		throw("wrong type");
	}
}

static bool
dbus_iter_append_from_qml(DBusMessageIter *iter, QVariant t, QVariant v)
{
	DBusMessageIter sub;
	QString type=t.toString();

	if (type == "boolean") {
		dbus_bool_t val=v.toInt();
		if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_BOOLEAN, &val))
			return false;
	} else if (type == "double") {
		double val=v.toDouble();
		if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_DOUBLE, &val))
			return false;
	} else if (type == "int16") {
		dbus_int16_t val=v.toInt();
		if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_INT16, &val))
			return false;
	} else if (type == "int32") {
		dbus_int32_t val=v.toInt();
		if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_INT32, &val))
			return false;
	} else if (type == "string") {
		QByteArray b=v.toString().toUtf8();
		const char *val=(const char *)b;
		if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_STRING, &val))
			return false;
	} else if (type == "uint8") {
		char val=v.toUInt();
		if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_BYTE, &val))
			return false;
	} else if (type == "uint16") {
		dbus_uint16_t val=v.toUInt();
		if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_UINT16, &val))
			return false;
	} else if (type == "uint32") {
		dbus_uint32_t val=v.toUInt();
		if (!dbus_message_iter_append_basic(iter, DBUS_TYPE_UINT32, &val))
			return false;
	} else if (type == "variant") {
		QVariantList va=v.value <QVariantList>();
		if (va.size() != 2)  {
			qDebug() << "variant must have 2 elements, not " << va.size();
			throw("variant must have 2 elements");
		}
        if (!dbus_message_iter_open_container(iter, DBUS_TYPE_VARIANT, signature_from_qml(va[0],va[1]).toLatin1(), &sub))
			return false;
		if (!dbus_iter_append_from_qml(&sub, va[0], va[1]))
			return false;
		if (!dbus_message_iter_close_container(iter, &sub))
			return false;
	} else if (type == "array") {
		QVariantList a=v.value <QVariantList>();
        if (a.size()%2) {
            qDebug() << "array must have even number of elements, not " << a.size();
            throw("array must have even number of elements");
        }
        if (!dbus_message_iter_open_container(iter, DBUS_TYPE_ARRAY, signature_from_qml(a[0],a[1]).toLatin1(), &sub))
            return false;
        for (int i = 0; i < a.size(); i+=2) {
            if (!dbus_iter_append_from_qml(&sub, a[i], a[i+1]))
                return false;
        }
        if (!dbus_message_iter_close_container(iter, &sub))
            return false;
	} else if (type == "structure") {
		QVariantList s=v.value <QVariantList>();
        if (s.size()%2) {
			qDebug() << "structure must have even number of elements, not " << s.size();
			throw("structure must have even number of elements");
		}
/*        //scan the structure to build the signature ? to be tested
        QString signature = QString(DBUS_STRUCT_BEGIN_CHAR);
        for (int i = 0; i < s.size(); i+=2) {
            signature += signature_from_qml(s[i],s[i+1]);
        }
        signature  += QString(DBUS_STRUCT_END_CHAR);
*/
        if (!dbus_message_iter_open_container(iter, DBUS_TYPE_STRUCT, NULL, &sub))
			return false;
		for (int i = 0; i < s.size(); i+=2) {
			if (!dbus_iter_append_from_qml(&sub, s[i], s[i+1]))
				return false;
		}
		if (!dbus_message_iter_close_container(iter, &sub))
			return false;
	} else if (type == "map") {
		QVariantList m=v.value <QVariantList>();
		if (m.size()%4) {
			qDebug() << "map must have multiple of four elements, not " << m.size();
			throw("map must have multiple of four elements");
		}
        if (!dbus_message_iter_open_container(iter, DBUS_TYPE_ARRAY, ("{"+signature_from_qml(m[0],m[1])+signature_from_qml(m[2],m[3])+"}").toLatin1(), &sub))
			return false;
		for (int i = 0; i < m.size(); i+=4) {
			DBusMessageIter entry;
			if (!dbus_message_iter_open_container(&sub, DBUS_TYPE_DICT_ENTRY, NULL, &entry))
				return false;
			if (!dbus_iter_append_from_qml(&entry, m[i], m[i+1]))
				return false;
			if (!dbus_iter_append_from_qml(&entry, m[i+2], m[i+3]))
				return false;
			if (!dbus_message_iter_close_container(&sub, &entry))
				return false;
		}
		if (!dbus_message_iter_close_container(iter, &sub))
			return false;
	} else {
		qDebug() << "append:Unknown type" << type;
		throw("wrong type");
	}
	return true;
}

static bool
dbus_message_from_qml_list(DBusMessage *msg, QVariant v)
{
	DBusMessageIter iter;
	dbus_message_iter_init_append(msg, &iter);

    // unbox the QVariant-QJSValue to fix the Qt 5.4 QML -> C++ QVariant issues
    if (v.userType() == qMetaTypeId<QJSValue>()) {
        v = v.value<QJSValue>().toVariant();
    }


    if (v.type() != QVariant::List) {
		qDebug() << "Wrong Variant Type" << v;
		return false;
	}
	QVariantList l = v.value < QVariantList > ();
	if (l.size()%2) {
		qDebug() << "argument list must have even number of elements, not " << l.size();
		throw("argument list must have even number of elements");
	}
	for (int i = 0; i < l.size(); i+=2) {
		if (!dbus_iter_append_from_qml(&iter, l[i], l[i+1]))
			return false;
	}
	return true;
}

void
DBusIfSignal::signal(void)
{
	QVariant v;
	v=qml_list_from_dbus_list(message().arguments());
#ifdef DEBUG
	qDebug() << "call " << m_slot << " with " << v;
#endif
    QMetaObject::invokeMethod(m_obj,m_slot.toLatin1(),Q_ARG(QVariant,v));
}

QObject *
 DBusIf::connect(QString service, QString path, QString interface, QString name, QObject *receiver, QString slot)
{
	DBusIfSignal *sig=new DBusIfSignal(service, path, interface, name, receiver, slot);
	sig->setParent(this);	
	return sig;
}


QVariant
 DBusIf::message(QString service, QString path, QString interface,
		 QString method, QVariant v)
{
	QDBusInterface iface(service, path, interface);
	QDBusMessage res;
	QVariant ret;

#if 0
	qDebug() << "Method call:" << "Service:" << service << "Path:" <<
	    path << "Interface:" << interface << "Method:" << method <<
	    "Args:" << v;
#endif
        DBusMessage *msg=dbus_message_new_method_call(service.toLatin1(), path.toLatin1(), interface.toLatin1(), method.toLatin1());
	if (dbus_message_from_qml_list(msg, v)) {
		DBusError error;
		dbus_error_init(&error);
        DBusConnection *session;
        session = dbus_bus_get(DBUS_BUS_SESSION, &error);
        if(!session) {
            QVariantList l,le;
            l.append(QString("error"));
            le.append((QString("Cannot access session bus")));
            l.append(QVariant(le));
            return QVariant(l);
        }
        DBusMessage *rmsg=dbus_connection_send_with_reply_and_block(session, msg, DBUS_TIMEOUT_USE_DEFAULT, &error);
        dbus_message_unref(msg);
		if (!rmsg) {
			QVariantList l,le;
			// qDebug() << "Message call failed";
			l.append(QString("error"));
			le.append(QString(error.name));
			le.append(QString(error.message));
			l.append(QVariant(le));
			dbus_error_free(&error);
			return QVariant(l);
		}
        //fprintf(stderr,"res=%p\n",rmsg);
		dbus_error_free(&error);
		ret=qml_list_from_dbus_message(rmsg);
        //qDebug() << ret;
		dbus_message_unref(rmsg);
	} else {
		dbus_message_unref(msg);
		QVariantList l,le;
		l.append(QString("error"));
		le.append(QString("Parse error"));
		le.append(QString("failed to parse argument list"));
		l.append(QVariant(le));
		return QVariant(l);
	}
#if 0
	qDebug() << "Args:" << ret;
#endif
	return ret;
}

void
DBusIf::quit(void)
{
	exit(0);
}

int
DBusIf::pid(void)
{
	return getpid();
}

