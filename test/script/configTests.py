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
* 7-11-2014, Philippe Colliot, Pass the host address as a parameter
*
* @licence end@

**************************************************************************
"""
import subprocess,os
from subprocess import call 

PATH_LOGREPLAYER='../../bin/log-replayer/src/'
PATH_LOGFILES='../resource/'

def launch(file,host): 
	FNULL = open(os.devnull,'w')
	logreplayer=PATH_LOGREPLAYER + 'log-replayer'
	file=PATH_LOGFILES + file
	call([logreplayer, file, host], stdout=FNULL, stderr=FNULL)



