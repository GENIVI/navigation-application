#!/bin/bash

navigation_version='497fe70ab183c2a968c8e488fde2e3ba143b141e'
positioning_version='48451e36a8c21afb00575227d27e10417c27878c'
navit_version='162a3e43d14531a7053872903674351a3142eea2'

echo "version of navigation is: $navigation_version"
echo "version of positioning is: $positioning_version"
echo "version of navit is: $navit_version"

echo -n "This script deletes, reloads and builds everything, are you sure ? (y or n) "
read input

if [ "$input" = 'n' ]
then
	exit 1
fi

if [ -d "./build" ]
then
	find ./build ! -name '*.cbp' -type f -exec rm -f {} +
fi
rm -rf navigation
rm -rf automotive-message-broker

git clone http://git.projects.genivi.org/lbs/navigation.git ./navigation
cd navigation
git checkout $navigation_version
cd src/navigation
git clone http://git.projects.genivi.org/lbs/positioning.git ./positioning
cd positioning
git checkout $positioning_version
cd ..
git clone https://github.com/navit-gps/navit.git
cd navit
git checkout $navit_version
patch -p0 -i ../patches/search_list_get_unique.diff
cd ../../../../

./rebuild_all.sh -c



