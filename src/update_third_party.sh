#!/bin/bash

navigation_version='9750f165bdc66490d8432ec4672c9c0186b6a31c'
positioning_version='d4c46f13019aefb11aebd0fc1210a29a46f0b521'
navit_version='7bba198ae2fd42f6092de74a64b9d544dc10e4ff'

echo "version of navigation is: $navigation_version"
echo "version of positioning is: $positioning_version"
echo "version of navit is: $navit_version"

echo "This script deletes and reloads all the third party software"
read -r -p "Are you sure ? [y/N] " input

case "$input" in
	[y/Y])
	rm -rf navigation
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
	patch -p0 -i ../patches/avoid-crash-on-guidance-when-delete-and-recreate-route.diff
	cd ../
	echo "Please rebuild with at least -c -n option"
	;;
	*)
	exit 1
	;;
esac






