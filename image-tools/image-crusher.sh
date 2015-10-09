#!/bin/bash
#
# Copyright 2015 Ian Leonard <antonlacon@gmail.com>
#
# This file is image-crusher.sh.
#
# image-crusher.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# image-crusher.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with image-crusher.sh. If not, see <http://www.gnu.org/licenses/>.
#
# Version: 20150819
#
# Usage: image-crusher {input} {output}
#
# Dependencies: graphicsmagick or imagemagick, mozjpeg, pngcrush
#
# To consider in future revision:
# Write a --help
# work the -perfect option into jpegtran usage - abort or switch to cjpeg?

# User Configuration Options:
mozjpeg_cjpeg_utility="${HOME}""/Downloads/mozjpeg/cjpeg"
mozjpeg_jpegtran_utility="${HOME}""/Downloads/mozjpeg/jpegtran"
#jpeg_compression_quality="99"

# die (message, exit code) - echo and abort message; use the provided exit code
die() {
  echo "$1"
    if [ -n "$2" ]; then
      exit "$2"
    else
      exit 1
    fi }

file="${1}"
output_file="${2}"

# Sanity checking
if [ -z "$file" ]; then
	die "Abort: No input file specified."
fi

if [ ! -e "$file" ]; then
	die "Abort: Specified input file does not exist."
fi

if [ -z "$output_file" ]; then
	die "Abort: No output file specified."
fi

if [ -e "$ouput_file" ]; then
	die "Abort: Output file already exists."
fi

if ! command -v convert > /dev/null || ! command -v identify > /dev/null; then
	die "Abort: Neither imagemagick nor graphicsmagick (compat mode) found." "1"
fi

# Main (input, output)

# see what type of file is being worked on
file_header=$( identify -format %m "${file}" )

# losslessly compress the jpeg file if it's already jpeg
# optimize a png when encountered
# convert a bmp to a png when found
# anything else? just copy it (comment is to make it a jpeg instead)
if [[ "$file_header" == "JPEG" ]]; then
	"$mozjpeg_jpegtran_utility" -optimize -copy none -outfile "$output_file" "${file}" || die "Abort: jpeg compression failed."
elif [[ "$file_header" == "PNG" ]]; then
	pngcrush -q -rem allb -reduce -brute "${file}" "${output_file}" || die "Abort: Failed to use pngcrush."
elif [[ "$file_header" == "BMP" ]]; then
	convert "${file}" "${output_file%.*}".png || die "Abort: Couldn't convert bmp to png."
else
	cp "${file}" "${output_file}" || die "Abort: Failed to copy file."
#	convert "${file}" TGA:- | "$mozjpeg_cjpeg_utility" -quality "$jpeg_compression_quality" -optimize -targa -outfile "$output_file" || die "Abort: jpeg creation failed."
fi

exit 0
