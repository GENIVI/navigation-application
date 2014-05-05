#!/usr/bin/python

"""
**************************************************************************
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2014, PCA Peugeot Citroen
*
* \file enter-a-destination.py
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
import configTests
import sys
import gobject

from threading import Timer
from configTests import *

PERIODICITY = 200 #in ms
END = 20*1000/PERIODICITY #20 s

def steps():
	global step
	if step < END:
		if step == 0:
			print 'step 1'
		launch("enter-a-destination.log")
		step = step + 1
		return True 
	else: 
		print '----End scenario: Enter a destination----'
		loop.quit()

print '----Start scenario: Enter a destination----'

# start 
step = 0
gobject.timeout_add(PERIODICITY,steps)
loop = gobject.MainLoop()
loop.run()

