#!/bin/sh
#
# Copyright 2015 Ian Leonard <antonlacon@gmail.com>
#
# This file is image-slicer.sh
#
# image-slicer.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the license.
#
# image-slicer.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERHCANTABILITY or FITNESS FOR A PARITCULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public LIcense
# along with image-slicer.sh. If not, see <http://www.gnu.org/licenses/>.
#
# Version: 20150928

INPUT_IMAGE=~/tmp-img/test.png
TEMP_DIR=~/tmp-img/test

# Can this be hardcoded? 853x480
IMAGE_HEIGHT=$( identify -ping -format '%h' "$INPUT_IMAGE" )
IMAGE_WIDTH=$( identify -ping -format '%w' "$INPUT_IMAGE" )

# Count the corners twice(?)
LEDS_TOP=30
LEDS_BOTTOM=30
LEDS_LEFT=20
LEDS_RIGHT=20

# Assume same number of LEDs on left as are on right
LED_VERTICAL=$(( IMAGE_HEIGHT / LEDS_LEFT ))

# Assume same number of LEDs on bottom as are on top
LED_HORIZONTAL=$(( IMAGE_WIDTH / LEDS_TOP ))

# Offset calculation for distance from 0,0
BOTTOM_OFFSET=$(( IMAGE_HEIGHT - LED_VERTICAL ))
RIGHT_OFFSET=$(( IMAGE_WIDTH - LED_HORIZONTAL ))

# Cut the borders off an image for analysis
# top
#convert "$INPUT_IMAGE" -crop "$IMAGE_WIDTH"x"$LED_VERTICAL"+0+0 +repage "$TEMP_DIR"/test-top-crop.miff
convert "$INPUT_IMAGE" -crop "$IMAGE_WIDTH"x"$LED_VERTICAL"+0+0 +repage miff:- | convert - -crop "$LED_HORIZONTAL"x"$LED_VERTICAL" +repage +adjoin "$TEMP_DIR"/tiles/top-tiles%02d.miff
# bottom
#convert "$INPUT_IMAGE" -crop "$IMAGE_WIDTH"x"$LED_VERTICAL"+0+"$BOTTOM_OFFSET" +repage "$TEMP_DIR"/test-bottom-crop.miff
convert "$INPUT_IMAGE" -crop "$IMAGE_WIDTH"x"$LED_VERTICAL"+0+"$BOTTOM_OFFSET" +repage miff:- | convert - -crop "$LED_HORIZONTAL"x"$LED_VERTICAL" +repage +adjoin "$TEMP_DIR"/tiles/bottom-tiles%02d.miff
# left
#convert "$INPUT_IMAGE" -crop "$LED_HORIZONTAL"x"$IMAGE_HEIGHT"+0+"$LED_VERTICAL" +repage "$TEMP_DIR"/test-left-crop.miff
convert "$INPUT_IMAGE" -crop "$LED_HORIZONTAL"x"$IMAGE_HEIGHT"+0+"$LED_VERTICAL" +repage miff:- | convert - -crop "$LED_HORIZONTAL"x"$LED_VERTICAL" +repage +adjoin "$TEMP_DIR"/tiles/left-tiles%02d.miff
# right
#convert "$INPUT_IMAGE" -crop "$LED_HORIZONTAL"x"$IMAGE_HEIGHT"+"$RIGHT_OFFSET"+"$LED_VERTICAL" +repage "$TEMP_DIR"/test-right-crop.miff
convert "$INPUT_IMAGE" -crop "$LED_HORIZONTAL"x"$IMAGE_HEIGHT"+"$RIGHT_OFFSET"+"$LED_VERTICAL" +repage miff:- | convert - -crop "$LED_HORIZONTAL"x"$LED_VERTICAL" +repage +adjoin "$TEMP_DIR"/tiles/right-tiles%02d.miff

# Cut the borders into equal sized tiles
# top
#convert "$TEMP_DIR"/test-top-crop.miff -crop "$LED_HORIZONTAL"x"$LED_VERTICAL" +repage +adjoin "$TEMP_DIR"/tiles/top-tiles%02d.miff
#convert "$TEMP_DIR"/test-top-crop.miff -crop "$LED_HORIZONTAL"x"$LED_VERTICAL" +repage +adjoin miff:- | convert - -scale 1x1\! histogram:- | identify -depth 8 -format %c - #"$TEMP_DIR"/tiles/top-tiles%02d.miff
# bottom
#convert "$TEMP_DIR"/test-bottom-crop.miff -crop "$LED_HORIZONTAL"x"$LED_VERTICAL" +repage +adjoin "$TEMP_DIR"/tiles/bottom-tiles%02d.miff
# left
#convert "$TEMP_DIR"/test-left-crop.miff -crop "$LED_HORIZONTAL"x"$LED_VERTICAL" +repage +adjoin "$TEMP_DIR"/tiles/left-tiles%02d.miff
# right
#convert "$TEMP_DIR"/test-right-crop.miff -crop "$LED_HORIZONTAL"x"$LED_VERTICAL" +repage +adjoin "$TEMP_DIR"/tiles/right-tiles%02d.miff

# Scale the tiles down to 1x1 pixels to average all colors present in tile
# top
counter=0
for i in "$TEMP_DIR"/tiles/*; do
#	convert "$i" -scale 1x1\! "$TEMP_DIR"/tiles/scaled-image-"$counter".miff
	convert "$i" -scale 1x1\! histogram:- | identify -depth 8 -format %c -
	let counter=counter+1
done
#convert "$TEMP_DIR"/tiles/top-tiles*.miff -scale 1x1 top-tiles-scaled%02d.miff
# bottom
#convert "$TEMP_DIR"/tiles/bottom-tiles*.miff -scale 1x1 bottom-tiles-scaled%02d.miff
# left
#convert "$TEMP_DIR"/tiles/left-tiles*.miff -scale 1x1 left-tiles-scaled%02d.miff
# right
#convert "$TEMP_DIR"/tiles/right-tiles*.miff -scale 1x1 right-tiles-scaled%02d.miff

exit
