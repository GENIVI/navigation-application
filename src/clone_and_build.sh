#!/bin/bash

build_option=""
navigation_version='f7ab563cd23182dcedaa7509b1ae66774addf181'
positioning_version='9725fe1f553197042d6445997690d452a73490c0'
navit_version='995cec54c8682fbabfb4f912b6156ce0b5b43436'

echo "version of navigation is: $navigation_version"
echo "version of positioning is: $positioning_version"
echo "version of navit is: $navit_version"

echo -n "This script deletes, reloads and builds everything, are you sure ? (y or n) "
read input

if [ "$input" = 'n' ]
then
	exit 1
fi

while getopts m opt
do
	case $opt in
	m)
		build_option="-m"
		;;
	\?)
		echo "Usage:"
		echo "$0 [-m]"
		echo "-m: build with commonAPI plugins "
		exit 1
	esac
done

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

./build.sh -c -n $build_option



