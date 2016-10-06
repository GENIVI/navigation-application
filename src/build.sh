#!/bin/bash

debug="OFF"
html="OFF"
clean=0
capi=0
navit=0
commonapi_tools_option=""

function check_path_for_capi
{
	echo 'check path for CommonAPI'
	if [ ! $COMMONAPI_TOOL_DIR ]
	then 
		echo 'Set the dir of the common api tools'
		echo 'export COMMONAPI_TOOL_DIR=<path>'
		exit 1
	fi

	if [ ! $COMMONAPI_DBUS_TOOL_DIR ]
	then 
		echo 'Set the dir of the common api dbus tools'
		echo 'export COMMONAPI_DBUS_TOOL_DIR=<path>'
		exit 1
	fi

	if [ ! $DBUS_LIB_PATH ]
	then 
		echo 'Set the dir of the patched dbus'
		echo 'export DBUS_LIB_PATH=<path>'
		exit 1
	fi
	commonapi_tools_option="-DDBUS_LIB_PATH="$DBUS_LIB_PATH" -DCOMMONAPI_DBUS_TOOL_DIR="$COMMONAPI_DBUS_TOOL_DIR" -DCOMMONAPI_TOOL_DIR="$COMMONAPI_TOOL_DIR""
}

while getopts cdmhn opt
do
	case $opt in
	c)
		clean=1
		;;
	d)
		debug="ON"
		;;
	m)
		capi=1
		;;
	h)
		html="ON"
		;;
	n)
		navit=1
		;;
	\?)
		echo "Usage:"
		echo "$0 [-cdmhn]"
		echo "-c: Rebuild with clean"
		echo "-d: Enable the debug messages"
		echo "-m: Build with commonAPI plugins "
		echo "-h: Enable migration to the html based hmi"
		echo "-n: Build navit"
		exit 1
	esac
done
set -e

if [ "$capi" = 1 ]
then
	check_path_for_capi
	cp ./hmi/qml/Core/genivi-capi.js ./hmi/qml/Core/genivi.js
else
	cp ./hmi/qml/Core/genivi-origin.js ./hmi/qml/Core/genivi.js
fi

if [ "$clean" = 1 ]
then
	if [ -d "./build" ]
	then
		if [ "$navit" = 1 ]
		then
			echo 'clean up the build folder and regenerate all the stuff'
			find ./build ! -name '*.cbp' -type f -exec rm -f {} +
		else
			echo 'clean up the build folder and regenerate all the stuff except navit '
			rm ./build/CMakeCache.txt
			rm ./build/cmake_install.cmake
			rm ./build/Makefile
		fi
	fi
else
	echo 'just build without generation of the hmi'
fi

mkdir -p build
cd build
mkdir -p navigation
cd navigation
mkdir -p navit
cd navit

if [ "$navit" = 1 ]
then
	echo 'build navit'
	if [ "$clean" = 1 ]
	then
		cmake -DDISABLE_QT=1 -DSAMPLE_MAP=0 -Dvehicle/null=1 -Dgraphics/qt_qpainter=0 ../../../navigation/src/navigation/navit/
	fi
	make
else
	if [ "$clean" = 1 ]
	then
		echo 'build navit'
		cmake -DDISABLE_QT=1 -DSAMPLE_MAP=0 -Dvehicle/null=1 -Dgraphics/qt_qpainter=0 ../../../navigation/src/navigation/navit/
		make
	fi
fi
cd ../../

echo 'build fsa'

if [ "$clean" = 1 ]
then
	if [ "$capi" = 0 ]
	then
		cmake -DWITH_HTML_MIGRATION=$html -DWITH_PLUGIN_MIGRATION=OFF -DWITH_DEBUG=$debug ../
	else
		cmake -DWITH_HTML_MIGRATION=$html -DWITH_PLUGIN_MIGRATION=ON -DWITH_DBUS_INTERFACE=OFF $commonapi_tools_option -DWITH_DEBUG=$debug ../
		echo 'fix a bug in the generation of CommonAPI hpp'
		sed -i -e 's/(const TimeStampedEnum::/(const ::v4::org::genivi::navigation::navigationcore::NavigationCoreTypes::TimeStampedEnum::/' ./navigation/franca/src-gen/v4/org/genivi/navigation/navigationcore/LocationInput.hpp
		sed -i -e 's/(const TimeStampedEnum::/(const ::v4::org::genivi::navigation::navigationcore::NavigationCoreTypes::TimeStampedEnum::/' ./navigation/franca/src-gen/v4/org/genivi/navigation/navigationcore/MapMatchedPosition.hpp
		sed -i -e 's/(const TimeStampedEnum::/(const ::v4::org::genivi::navigation::navigationcore::NavigationCoreTypes::TimeStampedEnum::/' ./poi-service/poi-server-capi/src-gen/v4/org/genivi/navigation/navigationcore/LocationInput.hpp
		sed -i -e 's/(const TimeStampedEnum::/(const ::v4::org::genivi::navigation::navigationcore::NavigationCoreTypes::TimeStampedEnum::/' ./poi-service/poi-server-capi/src-gen/v4/org/genivi/navigation/navigationcore/MapMatchedPosition.hpp
	fi
fi
make
cd ../

if [ "$clean" = 1 ]
then
	echo 'generate the hmi for gdp theme'
	cd script
	./prepare.sh -i ../hmi/qml/Core/gimp/gdp-theme/800x480
	cd ../
fi

