#!/usr/bin/python

"""
**************************************************************************
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2014, PCA Peugeot Citroen
*
* \file config-tests.py
*
* \brief This script is part of the FSA scenario.
*
* \author Philippe Colliot <philippe.colliot@mpsa.com>
*
* \version 1.0
*
* This Source Code Form is subject to the terms of the
* Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with
# this file, You can obtain one at http://mozilla.org/MPL/2.0/.

* List of changes:
* <date>, <name>, <description of change>
*
* @licence end@

**************************************************************************
"""
import subprocess
from subprocess import call

PATH_LOGREPLAYER='/genivi/positioning/build/log-replayer/src/'
PATH_LOGFILES='../resource/'

def launch(file): 
	logreplayer=PATH_LOGREPLAYER + 'log-replayer'
	file=PATH_LOGFILES + file
	arguments='> /dev/null 2>&1 &'
	print logreplayer
	print file
	call([logreplayer, file, arguments])



