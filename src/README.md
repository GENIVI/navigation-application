# Navigation application (including Fuel Stop Advisor)

## Synopsis
This folder contains a navigation application built on top of [navigation middleware](https://github.com/GENIVI/navigation) . Some test scripts are available into the ../test folder. 
The GENIVI APIs are implemented by navit plugins, running on DBus. 
The GENIVI APIs are implemented into Navit plugins, running on DBus. The HMI is made in Qml (Qt5.2.1 and QtQuick 2.1)

##Tested targets
Desktop: Tested under Ubuntu 16.04 LTS 64 bits
Hardware: Code is running on the [Genivi Demo Platform](https://github.com/GENIVI/genivi-dev-platform)  (Yocto based)

## Third parties software
Positioning from [https://github.com/GENIVI/positioning](https://github.com/GENIVI/positioning) 
Navit from [https://github.com/navit-gps/navit/](https://github.com/navit-gps/navit/)
Navigation middleware from [https://github.com/GENIVI/navigation](https://github.com/GENIVI/navigation) 
Automotive message broker (amb) from  [https://github.com/otcshare/automotive-message-broker.git](https://github.com/otcshare/automotive-message-broker.git) 
NB: navit and amb are patched
NB: For displaying current versions used by the code type ./reload.sh in command line 
NB: The code of positioning and navit is regularly aligned with the latest versions of the third parties software

## Prerequisites
Under Ubuntu, some packets are needed to be installed:
sudo apt-get install xsltproc libdbus-cpp-dev libdbus-c++-dev libglib2.0-dev gtk+-2.0 libglibmm-2.4-dev libxml++2.6-dev libgtk-3-dev libdbus-1-dev libsdl1.2-dev libsdl-image1.2-dev libsdl-ttf2.0-dev inkscape qt5-qmake qtbase5-dev-tools qtbase5-dev qttools5-dev-tools qtdeclarative5-dev qtdeclarative5-dialogs-plugin libboost-all-dev uuid-dev qtquick1.5-dev qtdeclarative5-qtquick2-plugin qt4-qmlviewer sqlite3 libsqlite3-dev

export QT_SELECT=5
Set language for the address list:
	export LANGUAGE=en_US

## How to build
### From scratch
A script allows to clone the third parties code (i.e. positioning, navigation, navit and amb) and rebuild all
./clone_and_build.sh
### Build
A script allows either:
to clean and rebuild all (invoking cmake) , including the HMI
./build.sh -c -t
or to build updated parts
./build.sh
NB: with -t option a tarball is also generated (used by the GDP)
## How to test
There's a file that contains some test case and the reminding issues (bug list)

##Directory Structure

navigation/map-viewer/
the plugins for the map rendering and manipulation (zoom, scroll..)
navigation/navigation-core/
the plugins for basic navigation features (location input, route calculation...)
navigation/poi-cam/
the plugins for poi content access module 
navigation/patches/
some patches to complete the navit code
navigation/map/
the map
navigation/navit/
basic code of navit
navigation/positioning/
the code of positioning
hmi/
the hmi in Qml
genivilogreplayer/
the plugin for amb that connects the logreplayer data (by using socket)
fuel-stop-advisor/
the code of the FSA application
automotive-message-broker/
the code of amb
script/
some scripts to build the hmi skins

##Known issues
NB: For issues concerning third parties, see the corresponding README.

For Qt version >= 5.2 with gcc 64 bits, there's an issue that needs to be fixed by compiling your code with -fPIC (-fPIE is not enough) 
You must build your code with position independent code if Qt was built with -reduce-relocations
For Qt version 5.4, it's needed to fix Qt 5.4 QML -> C++ QVariant issues by unboxing the QVariant-QJSValue
Potential issue may occur due to path change of freetype stuff. If necessary, add a link to /usr/include/freetype2/ into /usr/include 

##How to launch it in another area
It's possible to test it (experimental) in another area.
For instance, to locate the demo in Japan:
Get the map of Tokyo and suburbs by picking it from this site:
http://maps9.navit-project.org/api/map/?bbox=139.1,35.5,140.4,36.0&timestamp=170217
Rename the file to tokyo.bin, copy it to ./navigation/src/navigation/map
do ./build.sh -c
Launch the demo 
./run -r -c tokyo
NB: configuration is managed by a fsa.conf located in $HOME/.config/navigation and the run shell replaces it by the right one
