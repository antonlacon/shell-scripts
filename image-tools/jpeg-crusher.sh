#!/bin/bash
#
# Copyright 2015 Ian Leonard <antonlacon@gmail.com>
#
# This file is jpeg-crusher.sh.
#
# jpeg-crusher.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# jpeg-crusher.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with jpeg-crusher.sh. If not, see <http://www.gnu.org/licenses/>.
#
# Version: 20150703
#
# Usage: jpeg-crusher {input} {output}
#
# Dependencies: graphicsmagick or imagemagick, mozjpeg
#
# To consider in future revision:
# file scaling
# ignoring or respecting original aspect ratio
# Write a --help
# work the -perfect option into jpegtran usage - abort or switch to cjpeg?

# User Configuration Options:
mozjpeg_cjpeg_utility="${HOME}""/Downloads/mozjpeg/cjpeg"
mozjpeg_jpegtran_utility="${HOME}""/Downloads/mozjpeg/jpegtran"
compression_quality="95"

# die (message, exit code) - echo and abort message and use the provided exit code
die() {
  echo "$1"
    if [ -n "$2" ]; then
      exit "$2"
    else
      exit 1
    fi }

file="${1}"
output_file="${2}"

# Sanity checking common problems
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

# Use graphicsmagick first; fallback to imagemagick; abort if neither present.
if command -v gm > /dev/null; then
  convert_command="gm"
  identify_command="gm"
elif command -v convert > /dev/null && command -v identify > /dev/null; then
  convert_command="convert"
  identify_command="identify"
else
  die "Abort: No commands found to convert and identify images." "1"
fi

# Main (input, output)

# see what type of file is being worked on
if [[ "$identify_command" -eq "gm" ]]; then
	file_header=$( gm identify -format %m "${file}" )
else
	file_header=$( identify -format %m "${file}" )
fi

# losslessly compress the jpeg file if it's already jpeg, otherwise create a jpeg from original image
if [[ "$file_header" == "JPEG" ]]; then
	"$mozjpeg_jpegtran_utility" -optimize -copy none -outfile "$output_file" "${file}" || die "Abort: jpeg compression failed."
else
	if [[ "$convert_command" == "gm" ]]; then
		gm convert "${file}" TGA:- | "$mozjpeg_cjpeg_utility" -quality "$compression_quality" -optimize -targa -outfile "$output_file" || die "Abort: jpeg creation failed."
	else
		convert "${file}" TGA:- | "$mozjpeg_cjpeg_utility" -quality "$compression_quality" -optimize -targa -outfile "$output_file" || die "Abort: jpeg creation failed."
	fi
fi
