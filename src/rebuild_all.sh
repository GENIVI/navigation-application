#!/bin/bash

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
cmake ../../navigation/src/navigation
make
cd ..
echo 'build fsa'
cmake ../
make
cd ../
echo 'generate the hmi for gdp theme'
cd script
./prepare.sh -i ../hmi/qml/Core/gimp/gdp-theme/800x480
cd ../

