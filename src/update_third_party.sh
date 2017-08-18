#!/bin/bash

navigation_version='faed34d71ab44536cc077a6a6edf9e6903e40c1f'
positioning_version='9725fe1f553197042d6445997690d452a73490c0'
navit_version='28478e7f26c1a0eedc06fb4765e2f736079c6f0c'

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
	cd ../
	echo "Please rebuild with at least -c -n option"
	;;
	*)
	exit 1
	;;
esac






