#!/bin/bash

navigation_version='368cc50e9579d7ce7751c1a24c48072b9027592f'
positioning_version='f4f6b041f66fe7a02bd36f8f90918f9838292bed'
navit_version='42f9d3484516c88c7cdf647817a6d6a2acac53c2'

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
patch -p0 -i ../patches/fsa_issue_padding.diff
cd ../../../../

./rebuild_all.sh -c



