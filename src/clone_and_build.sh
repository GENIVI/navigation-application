#!/bin/bash

navigation_version='5ca0a6e28cf8dfcba41c299cc2b5340c7a0444f3'
positioning_version='9e65831eed02cc8a1b2e2e73787d6007b54214b4'
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

git clone https://github.com/GENIVI/navigation.git ./navigation
cd navigation
git checkout $navigation_version
cd src/navigation
git clone https://github.com/GENIVI/positioning.git ./positioning
cd positioning
git checkout $positioning_version
cd ..
git clone https://github.com/navit-gps/navit.git
cd navit
git checkout $navit_version
patch -p0 -i ../patches/search_list_get_unique.diff
patch -p0 -i ../patches/fsa_issue_padding.diff
cd ../../../../

./build.sh -c



