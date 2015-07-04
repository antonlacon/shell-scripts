#!/bin/sh
# Toggle a Synaptics TouchPad on/off. 
# Copyright 2012 Ian Leonard <antonlacon@gmail.com>
#
# This file is toggle-touchpad.sh.
#
# toggle-touchpad.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# toggle-touchpad.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with toggle-touchpad.sh. If not, see <http://www.gnu.org/licenses/>.

synaptics_status=$( xinput list-props "SynPS/2 Synaptics TouchPad" | grep "Synaptics Off" | cut -d ":" -f 2 | tr -d "	" )

if [ $synaptics_status -eq "0" ] ; then
	xinput set-int-prop "SynPS/2 Synaptics TouchPad" "Synaptics Off" 8 1
elif [ $synaptics_status -eq "1" ] ; then
	xinput set-int-prop "SynPS/2 Synaptics TouchPad" "Synaptics Off" 8 0
fi

exit 0
