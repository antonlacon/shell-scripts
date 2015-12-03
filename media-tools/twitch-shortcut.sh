#!/bin/bash
#
# Copyright 2015 Ian Leonard <antonlacon@gmail.com>
#
# This file is twitch-shortcut.sh.
#
# twitch-shortcut.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# twitch-shortcut.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with twitch-shortcut.sh. If not, see <http://www.gnu.org/licenses/>.
#
# Version: 20151201

# Twitch's stream quality settings: Source, Medium, Mobile, etc
stream_quality="Medium"

# Function to exit gracefully when something goes amiss
die() {
	echo "$1"
	exit 1
}

# Getting contents of the clipboard
broadcaster_channel=$( xclip -o )

# Check if clipboard contents resemble a twitch url and then try to obtain the stream's url
if [[ "$broadcaster_channel" == "http://"*"twitch.tv/"* ]]; then
	stream_url=$( youtube-dl -q -f "$stream_quality" --get-url "$broadcaster_channel" ) || \
	stream_url=$( youtube-dl -q -f "Source" --get-url "$broadcaster_channel" ) || \
	die "youtube-dl failed"
else
	die "bad clipboard content"
fi

# Launch video player
vlc "$stream_url"

exit 0
