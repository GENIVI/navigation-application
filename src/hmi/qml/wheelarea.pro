# @licence app begin@
# SPDX-License-Identifier: MPL-2.0
#
# \copyright Copyright (C) 2013-2014, PCA Peugeot Citroen
#
# \file wheelarea.pro
#
# \brief This file is part of the Build System.
#
# \author Martin Schaller <martin.schaller@it-schaller.de>
#
# \version 1.0
#
# This Source Code Form is subject to the terms of the
# Mozilla Public License (MPL), v. 2.0.
# If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# For further information see http://www.genivi.org/.
#
# List of changes:
# 
# <date>, <name>, <description of change>
#
# @licence end@
TEMPLATE = lib
CONFIG += qt plugin

DESTDIR = lib
OBJECTS_DIR = tmp
MOC_DIR = tmp
INCLUDEPATH += compat

HEADERS += plugin/wheelareaplugin.h plugin/wheelarea.h

SOURCES += plugin/wheelareaplugin.cpp 
