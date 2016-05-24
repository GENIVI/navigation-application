# Test files for Navigation application (including Fuel Stop Advisor)

## Synopsis
These folders contain several files that allow to test the FSA.
- Under ./script
Python scripts to proceed some unitary tests and to simulate the data for FSA
A bash script to monitor some DBus frames
- Under html-based-panel
A nodejs based stuff to simulate the data for FSA (prototype version)
##Tested targets
Desktop: Tested under Ubuntu 16.04 LTS 64 bits
## Python scripts
This test bench requires Python version >= 3.4 and uses pygame.
It's necessary to build it for Python3 
###Get pygame for Python3
(Thanks to http://www.pygame.org/wiki/CompileUbuntu)
1. install dependencies
sudo apt-get install mercurial python3-dev python3-numpy libav-tools     libsdl-image1.2-dev libsdl-mixer1.2-dev libsdl-ttf2.0-dev libsmpeg-dev     libsdl1.2-dev  libportmidi-dev libswscale-dev libavformat-dev libavcodec-dev
2. Grab source
hg clone https://bitbucket.org/pygame/pygame
3.Finally build and install
cd pygame
python3 setup.py build
sudo python3 setup.py install
### List of scripts
./script/set-position.py
Set a predefined position (from the ./resource/test-positioning.log)
./script/set-vehicle-info.py
Set predefined vehicle data (from the ./resource/test-vehicle-info.log)
./script/simulation-dashboard.py
The main test panel for FSA (see below)

## How to test the FSA with Python
NB: The test script is using the logreplayer to simulate position and vehicle data, so it's needed to launch the application without the logreplayer
NB: Before launching the application, assume no ./ambd/ambd process is running (kill -9 if necessary)
Launch the FSA:
./src/run -r

Launch the test dashboard (keyboard interface)
python3 simulation-dashboard.py

NB: To launch it remotely, you can set the host address, for instance: python3 simulation-dashboard.py -r 192.168.1.202 

Steps:
'i' launches initialization.log
's' launches start.log
'h' launches high-tank-level.log
'l' launches low-tank-level.log
'x' exits the dashboard (or close the window)

###Test scenario:

The main HMI of FSA is displayed
The test panel is displayed, with Lat 46.202 Lon 6.147 (Geneva area)

Click on trip computer button
(nothing is activated)
Into the test panel, enter 'i' 
Into the test panel, enter 'h'
Fuel level is 30 l, trip values are displayed after 400 m
Only tank distance is available (no guidance active)

Click on BACK button
Go to enter a destination
Go to enter a destination per address
Click on city button
Enter zuri..
Select Zürich into the list
Click on street button
Enter lamp..
Select In Lampitzäcken into the list
Click on OK button
Click on set as destination
(the GO TO button is activated)
Click on GO TO button
Route is calculated, DISTANCE = 286 km, TIME = 2:39:46
Click on ON button (to activate the guidance)
The map is displayed
To activate the simulation:
Click on Menu button
Click on settings button
(simulation panel)
Click on ON button to start the simulation
Simulation is started
Click on BACK button

Click on trip computer button
Enhanced tank distance is lower than tank distance but > 286 km (route total distance)
Into the test panel, enter 'l' 
Fuel level is 15 l, Enhanced tank distance is lower than  286 km !
Click on BACK button
Click on map
A F is diplayed, click on it
Into the poi menu, click on SEARCH
Select a full station
The info about the station are displayed
Click on REROUTE

