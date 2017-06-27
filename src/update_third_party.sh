#!/bin/bash

navigation=0
navit=0
navigation_version='4c3e24b04f8ff1e41a94f1c1dd181ae3412c3db9'
positioning_version='9725fe1f553197042d6445997690d452a73490c0'
navit_version='1e71b5fd4c0bf5ac96e5207c51db7d17057ed798'

if [ $# -lt 1 ] ; then 
	echo "Argument required, please enter -h "
	exit 1
fi

while getopts a:hn:d opt
do
	case $opt in
	a)
		navigation=1
		navigation_version=$OPTARG
		;;
	n)
		navit=1
		navit_version=$OPTARG
		;;
	d)
		navigation=1
		navit=1
		;;
	h)
		echo "Usage:"
		echo "$0 [-ahnd]"
		echo "-a <navigation version>: clean and load this version of navigation "
		echo "-h: Help"
		echo "-n <navit version>: clean and load this version of navit "
		echo "-d clean and load all with default version "
		exit 1
	esac
done

echo "version of navigation is: $navigation_version"
echo "version of positioning is: $positioning_version"
echo "version of navit is: $navit_version"

echo "This script deletes and reloads third party software"
echo -n "So rebuild will be necessary, are you sure ? (y or n) "
read input

if [ "$input" != 'y' ]
then
	exit 1
fi

if [ "$navigation" = 1 ]
then
	#it's needed to reload everything
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

else
	if [ "$navit" = 1 ]
	then
		#reload navit
		cd navigation/src/navigation
		git clone https://github.com/navit-gps/navit.git
		cd navit
		git checkout $navit_version
		patch -p0 -i ../patches/search_list_get_unique.diff
		patch -p0 -i ../patches/fsa_issue_padding.diff
		cd ../../../../
	fi
fi





