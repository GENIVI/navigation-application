#!/usr/bin/python3

"""
**************************************************************************
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2014, PCA Peugeot Citroen
*
* \file set-position.py
*
* \brief This script sets vehicle infos, thru the logreplayer.
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
import sys,tty,termios,select,pygame,gi,time,re,argparse
import pdb
 
from pygame.locals import *
from threading import Timer
from configTests import *
from enum import IntEnum
from gi.repository import GObject

class Step(IntEnum):
	START = 0
	END = 4

# Define some constants
KEYBOARD_PERIODICITY = 1000 #in ms
LOCAL_HOST = '127.0.0.1'

def getKeyboard():
    global step

    for event in pygame.event.get():
            if event.type == QUIT:
                    sys.exit(0)

    # get the keyboard input
    pygame.event.pump()
    keys = pygame.key.get_pressed()
    if keys[K_x]:
            step=Step.END

    if step==Step.START:
            launch("test-vehicle-info.log",host)
    elif step==Step.END:
            displayStatus( 'End test         ' )
            loop.quit()
    else:
            displayStatus( 'error' )
            pygame.quit()
            loop.quit()
    return True

# Main program begins here

# Initialize the game engine	
pygame.init()
host = LOCAL_HOST
step = Step.START
GObject.timeout_add(KEYBOARD_PERIODICITY,getKeyboard)
loop = GObject.MainLoop()
loop.run()
