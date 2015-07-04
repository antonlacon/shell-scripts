#!/bin/sh
#
# Copyright 2013 Ian Leonard <antonlacon@gmail.com>
#
# This file is archive-iso.sh.
#
# archive-iso.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# archive-iso.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with archive-iso.sh. If not, see <http://www.gnu.org/licenses/>.

dvd_device="/dev/sr0"
backup_library=" " # ADD LIBRARY PATH

# only uncomment if the CD/DVD does not include a volume id
iso_title="" # ADD ISO TITLE

#does not work with dual layer DVDs - stops reading at the end of the first layer
rom_info=$( isoinfo -d -i "${dvd_device}" )
# test to make sure this has contents

block_size=$( echo "${rom_info}" | grep "Logical block size" | cut -d " " -f 5 )
#block_count=$( echo "${rom_info}" | grep "Volume size is" | cut -d " " -f 4 )
#iso_title=$( echo "${rom_info}" | grep "Volume id" | cut -d " " -f 3 )

if [ -e "${backup_library}"/"${iso_title}".iso ]; then
        echo "Abort: Output file already exists." && exit 1
fi

#dd if="${dvd_device}" of="${backup_library}"/"${iso_title}".iso bs="${block_size}" count="${block_count}"
# witchraft to read in the input device once and both md5sum it and write the .iso file
md5_dvd=$( dd if="${dvd_device}" | tee > $( dd of="${backup_library}"/"${iso_title}".iso bs="${block_size}" ) | md5sum )
if [ ! $? -eq 0 ]; then
        echo "Abort: dd failed." && exit 1
fi

# md5sum verification
md5_iso=$( md5sum "${backup_library}"/"${iso_title}".iso )

echo "DVD md5sum: ""$md5_dvd"
echo "ISO md5sum: ""$md5_iso"
if [[ "${md5_dvd}" = "${md5_iso}" ]]; then
        echo "DVD and ISO md5sums match."
else
        echo "WARNING: ISO does not match original."
fi

exit 0
