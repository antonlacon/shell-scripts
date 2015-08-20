#!/bin/bash
# Merge King County, WA, USA ballot signature page with pages from original ballot to save on size and preserve clarity while emailing.
#
# Copyright 2012-2015 Ian Leonard <antonlacon@gmail.com>
#
# This file is king-county-vote-assist.sh.
#
# king-county-vote-assist.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# king-county-vote-assist.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with king-county-vote-assist.sh. If not, see <http://www.gnu.org/licenses/>.
#
# Order of pages for submission:
# Cover Sheet
# Ballot Signature
# Vote Selection
#
# Order of voter packet:
# Vote Selection
# Vote Instructions
# Ballot Signature
# Cover Sheet
# Postage Paid Envelope Cover
#
# Order of inputs: voter packet, signature page, desired output
#

PN="${0##*/}"

### LOCAL FUNCTIONS ###
# help()
help() {
	echo "Usage: ""${PN}"" [Voter's Packet] [Voter's Signature] [Output]"
	echo "Input files must be PDF documents."
}

# die(msg, code) - exit with a message and exit code
die() {
	echo "$1" # echo command's death report
	# use provided exit signal or default to 1
	if [ -n "$2" ]; then
		exit "$2"
	else
		exit 1
	fi
}
### END LOCAL FUNCTIONS ###
### PRE-CHECK ###
# check if $1 is a PDF file
if [[ $( file "${1}" ) =~ "PDF document" ]] && [[ $( file "${2}" ) =~ "PDF document" ]]; then
	VOTER_PACKET="${1}"
	BALLOT_SIGNATURE="${2}"
else
	help && die "Abort: Must provide PDF documents as voter packet." 1
fi

# check for output already existing
if [[ -e "${3}" ]]; then
	help && die "Abort: Output already exists." 1
else
	OUTPUT="${3}"
fi

# dependency check: pdftk
if ! command -v pdftk > /dev/null; then
	die "Abort: Could not locate pdftk." 1
fi
# dependency check: pdfinfo
if ! command -v pdfinfo > /dev/null; then
	die "Abort: Could not locate pdfinfo." 1
fi
### END PRE-CHECK ###
### MAIN ###
# Query number of pages in the voter packet
SIZE_OF_PDF="$( pdfinfo "${VOTER_PACKET}" | grep Pages )"
SIZE_OF_PDF="${SIZE_OF_PDF#*\ }"

# Subtract last 4 pages from the page count - vote instructions / envelope
(( COVER_SHEET = "${SIZE_OF_PDF}" - 1 ))
(( VOTER_SELECTION_END = "${SIZE_OF_PDF}" - 5 ))

pdftk A="${VOTER_PACKET}" B="${BALLOT_SIGNATURE}" cat A"${COVER_SHEET}" B A1-"${VOTER_SELECTION_END}"  output "${OUTPUT}"

exit 0
