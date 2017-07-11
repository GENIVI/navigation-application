/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2017, PSA GROUP
*
* \file dltif.cpp
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

#include "log.h"
#include "dltif.h"

DLT_DECLARE_CONTEXT(gCtx);

DLTIf::DLTIf(QQuickItem * parent)
:  QQuickItem(parent)
{
    DLT_REGISTER_APP("FSAC","FUEL STOP ADVISOR CLIENT");
    DLT_REGISTER_CONTEXT(gCtx,"FSAC","Global Context");
}

DLTIf::~DLTIf()
{

}

QString
DLTIf::name() const
{
    return m_name;
}

void
DLTIf::setName(const QString & name)
{
    m_name = name;
    LOG_INFO(gCtx,"Menu: %s",name.toStdString().c_str());
}

void DLTIf::log_info_msg(QString message)
{
    LOG_INFO(gCtx,"%s",message.toStdString().c_str());
}
