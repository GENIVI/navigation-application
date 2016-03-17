#!/usr/bin/python3

"""
**************************************************************************
* @licence app begin@
* SPDX-License-Identifier: MPL-2.0
*
* \copyright Copyright (C) 2014, PCA Peugeot Citroen
*
* \file test-positioning.py
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
import sys,tty,termios,select,pygame,gi,time,dbus,re,argparse
import pdb
 
from pygame.locals import *
from threading import Timer
from configTests import *
from enum import IntEnum
from dbus.mainloop.glib import DBusGMainLoop
from traceback import print_exc
from gi.repository import GObject

class Step(IntEnum):
	START = 0
	END = 4

class Genivi(IntEnum):
	ENHANCEDPOSITIONSERVICE_LATITUDE = 0x00000001
	ENHANCEDPOSITIONSERVICE_LONGITUDE = 0x00000002
	ENHANCEDPOSITIONSERVICE_ALTITUDE = 0x00000004
	FUELSTOPADVISOR_TANK_DISTANCE = 0x0022
	FUELSTOPADVISOR_ENHANCED_TANK_DISTANCE = 0x0024
	NAVIGATIONCORE_ACTIVE = 0x0060
	NAVIGATIONCORE_INACTIVE = 0x0061
	NAVIGATIONCORE_SIMULATION_STATUS_NO_SIMULATION = 0x0220
	NAVIGATIONCORE_SIMULATION_STATUS_RUNNING = 0x0221
	NAVIGATIONCORE_SIMULATION_STATUS_PAUSED = 0x0222
	NAVIGATIONCORE_SIMULATION_STATUS_FIXED_POSITION = 0x0223
	NAVIGATIONCORE_LATITUDE = 0x00a0
	NAVIGATIONCORE_LONGITUDE = 0x00a1

# Define some colors
BLACK = ( 0, 0, 0)
WHITE = ( 255, 255, 255)
BLUE = ( 0, 0, 255)
GREEN = ( 0, 255, 0)
RED = ( 255, 0, 0)
YELLOW = ( 255, 222, 0)

# Define some constants
PI = 3.141592653
KEYBOARD_PERIODICITY = 200 #in ms
GET_DBUS_PERIODICITY = 500 #in ms
FUEL_CONVERSION = (3.6/GET_DBUS_PERIODICITY)
SPEED_CONVERSION = (36.0/GET_DBUS_PERIODICITY)

# Item location on the screen
STATUS_LOCATION = (100,10)
STEP_LOCATION = (100,68)
ENGINE_SPEED_LOCATION = (150,118)
FUEL_LEVEL_LOCATION = (150,175)
FUEL_INSTANT_CONSUMPTION_LOCATION = (150,238)
VEHICLE_SPEED_LOCATION = (150,287)
LATITUDE_LOCATION = (64,340)
LONGITUDE_LOCATION = (185,340)
GUIDANCE_STATUS_LOCATION = (380,118)
SIMULATION_STATUS_LOCATION = (380,175)
FUEL_STOP_ADVISOR_WARNING_LOCATION = (380,238)
FUEL_STOP_ADVISOR_TANK_DISTANCE_LOCATION = (380,287)
FUEL_STOP_ADVISOR_ENHANCED_TANK_DISTANCE_LOCATION = (380,340)

# Defaults
LOCAL_HOST = '127.0.0.1'

def display(string,location,fontColor,fontBackground):
	global args
	text = font.render(string, True, fontColor, fontBackground)
	textRect = text.get_rect()
	textRect.topleft = location
	screen.blit(text, textRect)

def logVerbose(data,value):
	if args.ver==True:
		print (data,": ",value)

def displayStatus(string):
	display(string,STATUS_LOCATION,WHITE,BLUE)

def displayStep(string):
	display('                                ',STEP_LOCATION,YELLOW,BLACK)
	display(string,STEP_LOCATION,YELLOW,BLACK)

def displayEngineSpeed(string):
	display(string,ENGINE_SPEED_LOCATION,YELLOW,BLACK)
	logVerbose("EngineSpeed",string)

def displayFuelLevel(string):
	display(string,FUEL_LEVEL_LOCATION,YELLOW,BLACK)

def displayFuelInstant(string):
	display(string,FUEL_INSTANT_CONSUMPTION_LOCATION,YELLOW,BLACK)

def displayVehicleSpeed(string):
	display(string,VEHICLE_SPEED_LOCATION,YELLOW,BLACK)

def displayLatitude(string):
	display(string,LATITUDE_LOCATION,YELLOW,BLACK)

def displayLongitude(string):
	display(string,LONGITUDE_LOCATION,YELLOW,BLACK)

def displayGuidanceStatus(string):
	display(string,GUIDANCE_STATUS_LOCATION,YELLOW,BLACK)

def displaySimulationStatus(string):
	display(string,SIMULATION_STATUS_LOCATION,YELLOW,BLACK)

def displayFuelStopAdvisorWarning(string):
	display(string,FUEL_STOP_ADVISOR_WARNING_LOCATION,YELLOW,BLACK)

def displayFuelStopAdvisorTankDistance(string):
	display(string,FUEL_STOP_ADVISOR_TANK_DISTANCE_LOCATION,YELLOW,BLACK)

def displayFuelStopAdvisorEnhancedTankDistance(string):
	display(string,FUEL_STOP_ADVISOR_ENHANCED_TANK_DISTANCE_LOCATION,YELLOW,BLACK)

def refresh():
	pygame.display.update()

def initDisplay():
	displayStatus('')
	displayStep('')
	displayEngineSpeed('0')
	displayFuelLevel('0')
	displayFuelInstant('0')
	displayLatitude('0')
	displayLongitude('0')
	displayVehicleSpeed('0')
	displayGuidanceStatus('OFF')
	displaySimulationStatus('OFF')	
	displayFuelStopAdvisorWarning('-----')
	displayFuelStopAdvisorTankDistance('-----')
	displayFuelStopAdvisorEnhancedTankDistance('-----')
   
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

	return True 
   
def getDbus():
	global step
	global host

	# manage the logreplayer depending on the step
	if step==Step.START:
		launch("test-positioning.log",host)
	elif step==Step.END:
		displayStatus( 'End test         ' )
		loop.quit()
	else:
		displayStatus( 'error' )
		pygame.quit()
		loop.quit()

	displayStep( str(step.name) )

	# refresh screen
	refresh()

	return True 

def enhancedPositionPositionUpdateHandler(arg):
	time.sleep(.050)
	# get the position
	enhancedPosition = enhancedPositionInterface.GetPositionInfo(arg)
	if (arg & Genivi.ENHANCEDPOSITIONSERVICE_LATITUDE) == Genivi.ENHANCEDPOSITIONSERVICE_LATITUDE:
		latitude=float(enhancedPosition[1][dbus.UInt64(Genivi.ENHANCEDPOSITIONSERVICE_LATITUDE)])
		displayLatitude("{:.3f}".format(latitude))
	if (arg & Genivi.ENHANCEDPOSITIONSERVICE_LONGITUDE) == Genivi.ENHANCEDPOSITIONSERVICE_LONGITUDE:
		longitude=float(enhancedPosition[1][dbus.UInt64(Genivi.ENHANCEDPOSITIONSERVICE_LONGITUDE)])
		displayLongitude("{:.3f}".format(longitude))

# Main program begins here
parser = argparse.ArgumentParser(description='Test positioning.')
parser.add_argument('-v','--ver',action='store_true', help='Print log messages')
parser.add_argument('-r','--rem',action='store', dest='host', help='Set remote host address')
args = parser.parse_args()

if args.host != None:
	host = args.host
else:
	host = LOCAL_HOST

# Initialize the game engine	
pygame.init()

# Initialize the screen
background = pygame.image.load("dashboard.png")
backgroundRect = background.get_rect()
size = (width, height) = background.get_size()
screen = pygame.display.set_mode( size )
pygame.display.set_caption('Test positioning')
screen.blit(background,backgroundRect)
font = pygame.font.SysFont('Calibri', 25, True, False)
initDisplay()

# Initialize DBus loop as the main loop
DBusGMainLoop(set_as_default=True)

# Connect on the bus
dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
if host == LOCAL_HOST:
	dbusConnectionBus = dbus.SessionBus()
else:
	dbusConnectionBus = dbus.bus.BusConnection("tcp:host=" + host +",port=4000")

# Enhanced position
try:
	enhancedPositionObject = dbusConnectionBus.get_object("org.genivi.positioning.EnhancedPosition", "/org/genivi/positioning/EnhancedPosition")
except dbus.DBusException:
	print ("connection to Enhanced position failed")
	print_exc()
	sys.exit(1)
enhancedPositionInterface = dbus.Interface(enhancedPositionObject, "org.genivi.positioning.EnhancedPosition")
dbusConnectionBus.add_signal_receiver(enhancedPositionPositionUpdateHandler, dbus_interface = "org.genivi.positioning.EnhancedPosition", signal_name = "PositionUpdate")

displayStatus( 'Start positioning test' )

refresh()

# start 
step = Step.START
GObject.timeout_add(KEYBOARD_PERIODICITY,getKeyboard)
GObject.timeout_add(GET_DBUS_PERIODICITY,getDbus)

loop = GObject.MainLoop()
loop.run()



