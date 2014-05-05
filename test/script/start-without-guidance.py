#!/usr/bin/python

"""
**************************************************************************
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2014, PCA Peugeot Citroen
*
* \file start-without-guidance.py
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
END_STEP_1 = 1*1000/PERIODICITY #1 s
END_STEP_2 = 2*1000/PERIODICITY #2 s

def steps():
	global step
	if step < END_STEP_1:
		if step == 0:
			print 'step 1'
		launch("start-without-guidance-step1.log")
		step = step + 1
		return True 
	elif step < END_STEP_2:
		if step == END_STEP_1:
			print 'step 2'
		launch("start-without-guidance-step2.log")
		step = step + 1
		return True 
	else: 
		print '----End scenario: Start without guidance----'
		loop.quit()

print '----Start scenario: Start without guidance----'

# start 
step = 0
gobject.timeout_add(PERIODICITY,steps)
loop = gobject.MainLoop()
loop.run()

