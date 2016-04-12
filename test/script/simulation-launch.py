#!/usr/bin/python3

"""
**************************************************************************
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2014, PCA Peugeot Citroen
*
* \file simulation-launch.py
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
* 7-11-2014, Philippe Colliot, Add some parameters (host address)
*
* @licence end@
**************************************************************************
"""
import sys,tty,termios

from configTests import *

# Define some constants
LOCAL_HOST = '127.0.0.1'

simulation_files = {'START': "start.log", 'INITIALIZATION': "initialization.log", 'HIGH_TANK_LEVEL': "high-tank-level.log", 'LOW_TANK_LEVEL': "low-tank-level.log"};

# Main program begins here
host = LOCAL_HOST

launch(simulation_files[sys.argv[1]],host)


