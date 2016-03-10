#!/bin/bash

navigation_version='fe2954930afdf5d70a47ac3be5f02f3e301a33a2'
positioning_version='5b6b120d836259afb57b3ad6bf2f6ba8107c4a3e'
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

rm -rf build
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



