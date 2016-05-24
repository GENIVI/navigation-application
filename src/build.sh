#!/bin/bash

debug="OFF"
franca="OFF"
html="OFF"
clean=0

while getopts cdfh opt
do
	case $opt in
	c)
		clean=1
		;;
	d)
		debug="ON"
		;;
	f)
		franca="ON"
		;;
	h)
		html="ON"
		;;
	\?)
		echo "Usage:"
		echo "$0 [-cdfh]"
		echo "-c: Rebuild with clean"
		echo "-d: Enable the debug messages"
		echo "-f: Build using the Franca interfaces"
		echo "-h: Enable migration to the html based hmi"
		exit 1
	esac
done
set -e

if [ "$clean" = 1 ]
then
	echo 'clean up the build folder and regenerate all the stuff'
	if [ -d "./build" ]
	then
		find ./build ! -name '*.cbp' -type f -exec rm -f {} +
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

echo 'build navit'
if [ "$clean" = 1 ]
then
	cmake -DDISABLE_QT=1 -DSAMPLE_MAP=0 -Dvehicle/null=1 -Dgraphics/qt_qpainter=0 ../../../navigation/src/navigation/navit/
fi
make
cd ../

echo 'build navigation'
if [ "$clean" = 1 ]
then
	cmake -DWITH_DEBUG=$debug ../../navigation/src/navigation
fi
make
cd ..

echo 'build fsa'

if [ "$clean" = 1 ]
then
	cmake -DWITH_HTML_MIGRATION=$html -DWITH_FRANCA_DBUS_INTERFACE=$franca -DCOMMONAPI_DBUS_TOOL_DIR=$COMMONAPI_DBUS_TOOL_DIR -DCOMMONAPI_TOOL_DIR=$COMMONAPI_TOOL_DIR -DWITH_DEBUG=$debug ../
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

