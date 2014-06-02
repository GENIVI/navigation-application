#!/usr/bin/python

"""
**************************************************************************
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2014, PCA Peugeot Citroen
*
* \file simulation-dashboard.py
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
import sys,tty,termios,select,pygame,gobject,time,dbus,re
 
from pygame.locals import *
from threading import Timer
from configTests import *
from enum import Enum

class Step(Enum):
	START = 0
	INITIALIZATION = 1
	HIGH_TANK_LEVEL = 2
	LOW_TANK_LEVEL = 3
	END = 4

class Genivi(Enum):
	ENHANCEDPOSITIONSERVICE_LATITUDE = 0x0020
	ENHANCEDPOSITIONSERVICE_LONGITUDE = 0x0021
	ENHANCEDPOSITIONSERVICE_ALTITUDE = 0x0022

# Define some colors
BLACK = ( 0, 0, 0)
WHITE = ( 255, 255, 255)
BLUE = ( 0, 0, 255)
GREEN = ( 0, 255, 0)
RED = ( 255, 0, 0)
YELLOW = ( 255, 222, 0)

# Define some constants
PI = 3.141592653
PERIODICITY = 200 #in ms
CONVERSION = (3.6/PERIODICITY)

# Item location on the screen
STATUS_LOCATION = (100,10)
STEP_LOCATION = (150,68)
ENGINE_SPEED_LOCATION = (150,118)
FUEL_LEVEL_LOCATION = (150,175)
FUEL_INSTANT_CONSUMPTION_LOCATION = (150,238)
LATITUDE_LOCATION = (64,287)
LONGITUDE_LOCATION = (185,287)

def display(string,location,fontColor,fontBackground):
	text = font.render(string, True, fontColor, fontBackground)
	textRect = text.get_rect()
	textRect.topleft = location
	screen.blit(text, textRect)

def displayStatus(string):
	display(string,STATUS_LOCATION,WHITE,BLUE)

def displayStep(string):
	display(string,STEP_LOCATION,YELLOW,BLACK)

def displayEngineSpeed(string):
	display(string,ENGINE_SPEED_LOCATION,YELLOW,BLACK)

def displayFuelLevel(string):
	display(string,FUEL_LEVEL_LOCATION,YELLOW,BLACK)

def displayFuelInstant(string):
	display(string,FUEL_INSTANT_CONSUMPTION_LOCATION,YELLOW,BLACK)

def displayLatitude(string):
	display(string,LATITUDE_LOCATION,YELLOW,BLACK)

def displayLongitude(string):
	display(string,LONGITUDE_LOCATION,YELLOW,BLACK)

def refresh():
	pygame.display.update()

      
def steps():
	global step

	for event in pygame.event.get():
		if event.type == QUIT:
			sys.exit(0)

	# get the keyboard input
	pygame.event.pump()
	keys = pygame.key.get_pressed()
	if keys[K_i]:
		step=Step.INITIALIZATION
	elif keys[K_h]:
		step=Step.HIGH_TANK_LEVEL
	elif keys[K_l]:
		step=Step.LOW_TANK_LEVEL
	elif keys[K_x]:
		step=Step.END

	# manage the logreplayer depending on the step
	if step==Step.START:
		displayStep( str(step) )
		launch("start.log")
	elif step==Step.INITIALIZATION:
		displayStep( str(step) )
		launch("initialization.log")
	elif step==Step.HIGH_TANK_LEVEL:
		displayStep( str(step) )
		launch("high-tank-level.log")
	elif step==Step.LOW_TANK_LEVEL:
		displayStep( str(step) )
		launch("low-tank-level.log")
	elif step==Step.END:
		displayStatus( 'End simulation   ' )
		loop.quit()
	else:
		displayStatus( 'error' )
		pygame.quit()
		loop.quit()

	# get the values on amb
	engineSpeed = ambEngineSpeedInterface.GetEngineSpeed()
	displayEngineSpeed(str(int(engineSpeed[0])))
	fuelLevel = ambFuelInterface.GetLevel()
	displayFuelLevel(str(int(fuelLevel[0])))
	fuelInstCons = ambFuelInterface.GetInstantConsumption()
	displayFuelInstant(str(int(fuelInstCons[0])*CONVERSION))

	# get the geolocation
	geoLocation = enhancedPositionInterface.GetData(dbus.Array([Genivi.ENHANCEDPOSITIONSERVICE_LATITUDE,Genivi.ENHANCEDPOSITIONSERVICE_LONGITUDE,Genivi.ENHANCEDPOSITIONSERVICE_ALTITUDE]))
	latitude=float(geoLocation[dbus.UInt16(Genivi.ENHANCEDPOSITIONSERVICE_LATITUDE)])
	displayLatitude("{:.3f}".format(latitude))
	longitude=float(geoLocation[dbus.UInt16(Genivi.ENHANCEDPOSITIONSERVICE_LONGITUDE)])
	displayLongitude("{:.3f}".format(longitude))

	# refresh screen
	refresh()

	return True 

# Initialize the game engine	
pygame.init()

# Initialize the screen
background = pygame.image.load("dashboard.png")
backgroundRect = background.get_rect()
size = (width, height) = background.get_size()
screen = pygame.display.set_mode( size )
pygame.display.set_caption('Simulation dashboard')
screen.blit(background,backgroundRect)
font = pygame.font.SysFont('Calibri', 25, True, False)

# Connect on the bus
dbusConnectionBus = dbus.SessionBus()

# Automotive message broker
ambObject = dbusConnectionBus.get_object("org.automotive.message.broker", "/")
ambInterface = dbus.Interface(ambObject, "org.automotive.Manager")

# Get the object path to retrieve Engine Speed
engineSpeedPath = ambInterface.FindObject("EngineSpeed");
ambEngineSpeed = dbusConnectionBus.get_object("org.automotive.message.broker", engineSpeedPath[0])
ambEngineSpeedInterface = dbus.Interface(ambEngineSpeed, "org.automotive.EngineSpeed")

# Get the object path to retrieve Fuel Level and Instant consumption
fuelPath = ambInterface.FindObject("Fuel");
ambFuel = dbusConnectionBus.get_object("org.automotive.message.broker", fuelPath[0])
ambFuelInterface = dbus.Interface(ambFuel, "org.automotive.Fuel")

# Enhanced position
enhancedPositionObject = dbusConnectionBus.get_object("org.genivi.positioning.EnhancedPosition", "/position")
enhancedPositionInterface = dbus.Interface(enhancedPositionObject, "org.genivi.positioning.EnhancedPosition")

displayStatus( 'Start simulation' )

refresh()

# start 
step = Step.START
gobject.timeout_add(PERIODICITY,steps)
loop = gobject.MainLoop()
loop.run()



