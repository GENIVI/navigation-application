/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2017, PSA Group
*
* \file translator.h
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
#ifndef INCLUDE_TRANSLATOR
#define INCLUDE_TRANSLATOR

#include <QApplication>
#include <QObject>
#include <QTranslator>
#include <QDebug>
#include <QDir>
#include <QGuiApplication>

class Translator : public QObject
{
    Q_OBJECT

public:
    explicit Translator(QObject *parent = 0) : QObject(parent) {}

signals:
    void languageChanged(QString);

public:
    Q_INVOKABLE inline void setTranslation(const QString translation) {
        QDir dir = QDir(qApp->applicationDirPath()).absolutePath();
        if(!mp_translator.load(translation, dir.path()))
        {
            qDebug() << "Failed to load translation file";
        }else{
            qApp->installTranslator(&mp_translator);
            m_translation=translation;
            emit languageChanged(translation);
        }
    }
    Q_INVOKABLE inline QString getCurrentTranslation() const {return m_translation; }
    Q_INVOKABLE inline QString getEmptyString() const {return QString();}

private:
    QTranslator mp_translator;
    QString m_translation;
};

Q_DECLARE_METATYPE(Translator*)

#endif
