# common.lib.sh v20120610
#
# Copyright 2011-2012: Ian Leonard <antonlacon@gmail.com>
#
# This file is common.lib.sh.
#
# common.lib.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# common.lib.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with common.lib.sh. If not, see <http://www.gnu.org/licenses/>.
#
# Stores common functions for shell scripts
#
# Functions:
# die
# generate_alphanumeric
# generate_alphanumeric_string
# tmp_random_name

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

# generate_alphanumeric()
# output a single alphanumeric character

generate_alphanumeric() {
	# [a-zA-Z0-9]
	local character_array=(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9)

	# choose a random number between 0 and 61 (26 lowercase, 26 uppercase, 10 digits)
	local i=$RANDOM

	while [ $i -gt 61 ]; do
		i=$RANDOM
	done
	echo ${character_array[$i]}
}

# generate_alphanumeric_string(int)
# output an alphanumeric string of length positive int
#

generate_alphanumeric_string() {
	local name_length=$1
	local tmp_string=""
	local i=0

	# test if temp_dir/tmp_name exists, if it does, repeat
	while [ $i -lt $name_length ]; do
		tmp_string=$tmp_string$( generate_alphanumeric )
		(( i = i+1 ))
	done
	echo $tmp_string
}

# tmp_random_name()
# Create a temporary filename for use by another command
# Name will be alphanumeric not currently in the designated directory
# Use mktemp if it's available, otherwise try and mimic it.
#
# NOTE: There is no guarantee this filename will remain available, making this potentially UNSAFE.
#
# requires the following to be set prior to calling
# TEMP_DIR
# PN

tmp_random_name() {
	if command -v mktemp > /dev/null; then
		local tmp_name=$( basename $( mktemp -u --tmpdir="${TEMP_DIR}" "${PN}".XXXXXXXXXX ) )
		echo "${tmp_name}"
	else
		local tmp_name=$( generate_alphanumeric_string 10 )

		while [ -e "${TEMP_DIR}/${PN}.$tmp_name" ]; do
			tmp_name=$( generate alphanumeric_string 10 )	
		done
		echo "${PN}.${tmp_name}"
	fi
}
