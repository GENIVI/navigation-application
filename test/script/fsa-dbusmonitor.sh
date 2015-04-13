#!/bin/bash

OBJECT1="'org.genivi.positioning.EnhancedPosition'"
INTERFACE1="'org.genivi.positioning.EnhancedPosition'"
DBUSPATH1="'/org/genivi/positioning/EnhancedPosition'"

OBJECT2="'org.genivi.navigationcore.MapMatchedPosition'"
INTERFACE2="'org.genivi.navigationcore.MapMatchedPosition'"
DBUSPATH2="'/org/genivi/navigationcore'"

WATCH1="type='signal', sender=${OBJECT1}, interface=${INTERFACE1}, path=${DBUSPATH1}, member='PositionUpdate'"
WATCH2="type='method_call', interface=${INTERFACE1}, path=${DBUSPATH1}, member='GetPositionInfo'"
WATCH3="type='method_call', interface=${INTERFACE2}, path=${DBUSPATH2}, member='GetPosition'"

dbus-monitor "${WATCH1}" "${WATCH2}" "${WATCH3}" | \
awk '
/member='PositionUpdate' && interface=${INTERFACE1} / { print "Position updated by enhanced: "; getline; print "value: " substr($2,1,2) }
/member='GetPositionInfo'/ { print "Get position on enhanced: "; print substr($3,1,20); getline; print "value: " substr($2,1,2) }
/member='PositionUpdate' && interface=${INTERFACE2} / { print "Position updated by map matched: "; getline; print "value: " substr($2,1,2) }
/member='GetPosition'/ { print "Get position on map matched: "; print substr($3,1,20); getline; getline; while (substr($1,1,6) == "uint16") { print "value: " substr($2,1,3); getline}  }
'


