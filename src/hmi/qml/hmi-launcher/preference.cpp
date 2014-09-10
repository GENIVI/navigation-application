/**
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
*
* \file preference.cpp
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
#include <sys/types.h>
#include <unistd.h>
#include "preference.h"

Preference::Preference(QObject *parent)
 : QObject(parent)
 {
    m_source = 0;
    m_mode = 0;
 }

 unsigned int Preference::source() const
 {
     return m_source;
 }

 void Preference::setSource(const unsigned int &source)
 {
     m_source = source;
 }

 unsigned int Preference::mode() const
 {
     return m_mode;
 }

 void Preference::setMode(const unsigned int &mode)
 {
     m_mode = mode;
 }

