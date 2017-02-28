#!/bin/bash
#
# Copyright 2015 Ian Leonard <antonlacon@gmail.com>
#
# This file is image-slicer-mpr.sh
#
# image-slicer-mpr.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the license.
#
# image-slier-mpr.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with image-slicer-mpr.sh. If not, see <http://www.gnu.org/licenses/>.
#
# Version: 20151008
#
# This script will not work with Graphicsmagick as written - needs changes in the averaging of colors to return RGB at a minimum

PN="${0##*/}"
INPUT_IMAGE=~/ambilight/test.png
TEMP_DIR=$( mktemp -d /tmp/"${PN}".XXXXXX )

# Is there a benefit to hardcoding? What problems would it yield? 853x480
IMAGE_DIMENSIONS=$( identify -format '%hx%w' "$INPUT_IMAGE" )
IMAGE_HEIGHT=${IMAGE_DIMENSIONS%x*}
IMAGE_WIDTH=${IMAGE_DIMENSIONS#*x}

# Count the corners twice for dimensioning
LEDS_TOP=30
LEDS_BOTTOM=30
LEDS_LEFT=20
LEDS_RIGHT=20

# Assume same number of LEDs on left as are on right
LED_VERTICAL=$(( IMAGE_HEIGHT / LEDS_LEFT ))

# Assume same number of LEDs on bottom as are on top
LED_HORIZONTAL=$(( IMAGE_WIDTH / LEDS_TOP ))

# Subtract 2 LEDs off each side to prevent double counting corners
LEDS_LEFT=$(( LEDS_LEFT - 2 ))
LEDS_RIGHT=$(( LEDS_RIGHT - 2 ))

# Offset calculation for distance from 0,0 or only doing a partial cut along the side
BOTTOM_OFFSET=$(( IMAGE_HEIGHT - LED_VERTICAL ))
RIGHT_OFFSET=$(( IMAGE_WIDTH - LED_HORIZONTAL ))
SIDE_OFFSET=$(( IMAGE_HEIGHT - LED_VERTICAL*2 ))

# Cut the borders off an image for analysis, tile them into equalish segments, scales to 1x1 to average colors present, and then prints a RGB value

convert "$INPUT_IMAGE" -write mpr:video_frame +delete \
	\( mpr:video_frame -crop "$IMAGE_WIDTH"x"$LED_VERTICAL"+0+0 -crop "$LEDS_TOP"x1@ +repage +adjoin -scale 1x1\! -format '%[fx:int(255*r+.5)] %[fx:int(255*g+.5)] %[fx:int(255*b+.5)]\n' +write info:"${TEMP_DIR}"/top-leds-%02d.txt +delete \) \
	\( mpr:video_frame -crop "$IMAGE_WIDTH"x"$LED_VERTICAL"+0+"$BOTTOM_OFFSET" -crop "$LEDS_BOTTOM"x1@ +repage +adjoin -scale 1x1\! -format '%[fx:int(255*r+.5)] %[fx:int(255*g+.5)] %[fx:int(255*b+.5)]\n' +write info:"${TEMP_DIR}"/bottom-leds-%02d.txt +delete \) \
	\( mpr:video_frame -crop "$LED_HORIZONTAL"x"$SIDE_OFFSET"+0+"$LED_VERTICAL" -crop 1x"$LEDS_LEFT"@ +repage +adjoin -scale 1x1\! -format '%[fx:int(255*r+.5)] %[fx:int(255*g+.5)] %[fx:int(255*b+.5)]\n' +write info:"${TEMP_DIR}"/left-leds-%02d.txt +delete \) \
	\( mpr:video_frame -crop "$LED_HORIZONTAL"x"$SIDE_OFFSET"+"$RIGHT_OFFSET"+"$LED_VERTICAL" -crop 1x"$LEDS_RIGHT"@ +repage +adjoin -scale 1x1\! -format '%[fx:int(255*r+.5)] %[fx:int(255*g+.5)] %[fx:int(255*b+.5)]\n' +write info:"${TEMP_DIR}"/right-leds-%02d.txt +delete \) \
	NULL:

# Store convert command output in variable. Split the variable into an RGB array using RegEx
for i in "$TEMP_DIR"/*; do
	RGB_VALUES=( $(<"$i") ) # read in file, break into list using spaces to separate variables
	R_VALUE=${RGB_VALUES[0]}
	G_VALUE=${RGB_VALUES[1]}
	B_VALUE=${RGB_VALUES[2]}
	# issue command to LEDs to change color based on above - need a link between file being processed and LED to change
	# Concatenate all of the leds into one file and read it in that order? Do it by the side and then process in parallel?
	# add a fourth value to the RGB pair above and it would be the LEDs position..? then process all the led changes in parallel
	# is there a brightness setting on the leds?
	echo "$i": "$R_VALUE","$G_VALUE","$B_VALUE"
	# research how these values get to the LED strip
done

# destroy temporary files

exit
