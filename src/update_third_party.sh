#!/bin/bash

navigation_version='97a5523dc344b8258069ba90a161dda6f93fbd59'
positioning_version='d4c46f13019aefb11aebd0fc1210a29a46f0b521'
navit_version='a9fd119415fe451536354b24ca2ac73ead2d4dec'

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






