#!/bin/bash

debug="OFF"
franca="OFF"
html="OFF"

while getopts dfh opt
do
	case $opt in
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
		echo "$0 [-dfh]"
		echo "-d: Enable the debug messages"
		echo "-f: Build using the Franca interfaces"
		echo "-h: Enable migration to the html based hmi"
		exit 1
	esac
done
set -e

echo 'delete the build folder'
rm -rf build

mkdir build
cd build
mkdir navigation
cd navigation
mkdir navit
cd navit
mkdir navit
cd navit

echo 'build navit'
cmake -DDISABLE_QT=1 -DSAMPLE_MAP=0 -Dvehicle/null=1 -Dgraphics/qt_qpainter=0 ../../../../navigation/src/navigation/navit/navit/
make
cd ../../

echo 'build navigation'
cmake -DWITH_DEBUG=$debug ../../navigation/src/navigation
make
cd ..

echo 'build fsa'
cmake -DWITH_HTML_MIGRATION=$html -DWITH_FRANCA_DBUS_INTERFACE=$franca -DCOMMONAPI_DBUS_TOOL_DIR=$COMMONAPI_DBUS_TOOL_DIR -DCOMMONAPI_TOOL_DIR=$COMMONAPI_TOOL_DIR -DWITH_DEBUG=$debug ../
make
cd ../

echo 'generate the hmi for gdp theme'
cd script
./prepare.sh -i ../hmi/qml/Core/gimp/gdp-theme/800x480
cd ../

