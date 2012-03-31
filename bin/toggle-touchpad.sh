#!/bin/sh
# Toggle Synaptics TouchPad on/off. 

synaptics_status=$( xinput list-props "SynPS/2 Synaptics TouchPad" | grep "Synaptics Off" | cut -d ":" -f 2 | tr -d "	" )

if [ $synaptics_status -eq "0" ] ; then
	xinput set-int-prop "SynPS/2 Synaptics TouchPad" "Synaptics Off" 8 1
elif [ $synaptics_status -eq "1" ; then
	xinput set-int-prop "SynPS/2 Synaptics TouchPad" "Synaptics Off" 8 0
fi

exit
