# media.lib.sh v20150825
#
# Copyright 2011-2015: Ian Leonard <antonlacon@gmail.com>
#
# This file is media.lib.sh.
#
# media.lib.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# media.lib.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with media.lib.sh. If not, see <http://www.gnu.org/licenses/>.
#
# Common multimedia related functions to assist in shell scripting
#
# Exit Codes:
# 1: reserved for calling script
# 2: audio related
# 3: video related
# 4: general failure
#
# Functions Provided:
# ClearMediaInfo
# CopyAudio
# CreateAudioPipe
# CreateVideoPipeResize
# CreateVideoPipeResizePreserveAspect
# CreateVideoPipeStraightThrough
# DestroyPipe
# EncodeAudio_FlacFlac
# EncodeAudio_MP4AAC
# EncodeAudio_OggOpus
# EncodeAudio_OggVorbis
# GatherMediaInfo
# QueryAudioCodec
# QueryVideoDisplayAspectRatio
# QueryVideoFPS
# QueryVideoHeight
# QueryVideoSampleAspectRatio #Incomplete
# QueryVideoWidth
# TestForAudio
# TestForVideo
#
# Known quirks / To Do:
# Using ffmpeg's hwaccel option for CreateVideoPipe* doesn't background; hangs somewhere. Check if issue with pipe or file?
# Confirm mplayer's hardware acceleration is working - mplayer config is for vo vdpau, this uses yuv4mpeg
# Every query not using ffprobe probably won't work with multiple streams
#	ffprobe forced to use first stream's information
#	Video queries should use first stream - 2nd stream is typically mjpeg
#	Audio queries don't know how to handle multiple streams - write QueryAudioStreamMap - meant for 5.1 -> 2.0, not this?
#	Consider switching default stream to tbe the longest - does ffmpeg -show_stream have a stream select?
# Teach CreateAudioPipe to handle dynamic channel amounts. Less of an issue - 2 channel for stereo pmp, and rips have audio copied.
# Rename CreateVideoPipeStraightThrough to just CreateVideoPipe
# Write DetectVideoCrop
# Write QueryVideoCodec
# Add audio channel support to EncodeAudio_MP4AAC

# Functions:

# ClearMediaInfo()
# Unset the GatherMediaInfo variable

ClearMediaInfo() {
	unset -v QUERY_MEDIA_TOOL MEDIA_INFO
}

# CopyAudio(input file, output file)
# Copy the audio stream from one file into a new file.
#
# Relies on invoker to set the following VARIABLES:
# no variables

CopyAudio() {
	if command -v ffmpeg > /dev/null; then
		ffmpeg -i "${1}" -vn -acodec copy -sn "${2}" || die "Abort: ffmpeg failed in CopyAudio." "2"
	else
		die "Abort: No known programs found to copy an audio stream." "2"
	fi
}

# CreateAudioPipe(input file)
# Opens a named pipe and fills it with the audio output of a file
# Requirements: ffmpeg or mplayer, mkfifo, common.sh.lib
# See also: DestroyPipe
#
# Relies on invoker to set the following VARIABLES:
# TEMP_DIR

CreateAudioPipe() {
	# fixme: implement QueryAudioChannels?
	AUDIO_CHANNELS=2

	AUDIO_PIPE=$( tmp_random_name )
	echo "CreateAudioPipe named pipe is: "$AUDIO_PIPE

	# Test for existence of audiopipe already
	if [ -e "${TEMP_DIR}"/"${AUDIO_PIPE}" ]; then
		die "Abort: Named pipe file already exists." "2"
	else
		mkfifo "${TEMP_DIR}"/"${AUDIO_PIPE}" || die "failed to create named pipe" "2"
	fi

	# Make a named pipe and fill it with transcoder's output in WAV format.
	# Select an audio transcoder to output WAV: (ffmpeg, mplayer)
	if command -v ffmpeg > /dev/null; then
		ffmpeg -i "${1}" -acodec pcm_s16le -ac "${AUDIO_CHANNELS}" -f wav -y "${TEMP_DIR}"/"${AUDIO_PIPE}" &>/dev/null &
	elif command -v mplayer > /dev/null; then
		mplayer -really-quiet -nocorrect-pts -vo null -vc null -ao pcm:waveheader:fast:file="${TEMP_DIR}"/"${AUDIO_PIPE}" "${1}" &
	else
		die "Abort: No supported audio transcoder detected." "2"
	fi

	if [ "$?" -ne 0 ]; then
		die "Abort: Failed to fill named pipe." "2"
	fi
}

# CreateVideoPipeResize(input file)
# Creates a named pipe with transcoded video that has been resized to device dimensions, regardless of aspect ratio
# Requirements: mplayer, mkfifo
#
# Relies on invoker to set the following VARIABLES:
# TEMP_DIR
# DEVICE_HEIGHT
# DEVICE_WIDTH

CreateVideoPipeResize() {
	VIDEO_PIPE=$( tmp_random_name )
	echo "CreateVideoPipeResize named pipe is: "${VIDEO_PIPE}

	# Test for existence of videopipe already
	if [ -e "${TEMP_DIR}"/${VIDEO_PIPE} ]; then
		die "Abort: Named pipe file already exists." "3"
	else
	        mkfifo "${TEMP_DIR}"/${VIDEO_PIPE} || die "failed to create named pipe" "3"
	fi

#	if command -v mplayer > /dev/null; then
	        # mplayer's vf filter chain scales video to device's display width and height regardless of aspect ratio
#	        mplayer -really-quiet -nosub -nosound -benchmark -sws 9 -vf scale="${DEVICE_WIDTH}":"${DEVICE_HEIGHT}" -vo yuv4mpeg:file="${TEMP_DIR}"/${VIDEO_PIPE} "${1}" &
	if command -v ffmpeg > /dev/null; then
		ffmpeg -i "${1}" -filter:v scale="${DEVICE_WIDTH}":"${DEVICE_HEIGHT}" -sws_flags lanczos -f yuv4mpegpipe -an -sn -y "${TEMP_DIR}"/"${VIDEO_PIPE}" 2>/dev/null &
	else
		die "Abort: No supported video transcoder detected." "3"
	fi

	if [ "$?" -ne 0 ]; then
		die "Abort: Failed to fill named pipe." "3"
	fi
}

# CreateVideoPipeResizePreserveAspect(input file)
# Creates a named pipe with transcoded video that has been resized and adjusted to preserve the original content's aspect ratio when being used on a device with a different aspect ratio
# Requirements: mplayer, mkfifo
#
# Relies on invoker to set the following VARIABLES:
# DEVICE_ASPECT_RATIO
# DEVICE_HEIGHT
# TEMP_DIR
# DEVICE_WIDTH

CreateVideoPipeResizePreserveAspect() {
	VIDEO_PIPE=$( tmp_random_name )
	echo "CreateVideoPipeResizePreserveAspect named pipe is: "${VIDEO_PIPE}

	# Test for existence of videopipe already
	if [ -e "${TEMP_DIR}"/${VIDEO_PIPE} ]; then
		die "Abort: Named pipe file already exists." "3"
	else
	        mkfifo "${TEMP_DIR}"/${VIDEO_PIPE} || die "failed to create named pipe" "3"
	fi

### FFmpeg approach has audio sync issue when doing 16/9 to 4/3 (bars). No issues noticed 4/3 to 16/9 (letterbox). ###

#	if command -v mplayer > /dev/null; then
	        # mplayer's vf filter chain resizes to DEVICE_ASPECT_RATIO of player while maintaining original aspect ratio of the video
#	        mplayer -really-quiet -nosub -nosound -benchmark -sws 9 -vf dsize="$DEVICE_WIDTH":"$DEVICE_HEIGHT",scale=0:0,expand="$DEVICE_WIDTH":"$DEVICE_HEIGHT",dsize="${DEVICE_ASPECT_RATIO}" -vo yuv4mpeg:file="${TEMP_DIR}"/${VIDEO_PIPE} "${1}" &
	if command -v ffmpeg > /dev/null; then
		ffmpeg -i "${1}" \
		-filter:v scale="iw*min("${DEVICE_WIDTH}"/iw\,"${DEVICE_HEIGHT}"/ih):ih*min("${DEVICE_WIDTH}"/iw\,"${DEVICE_HEIGHT}"/ih)",pad="${DEVICE_WIDTH}"":""${DEVICE_HEIGHT}"":(ow-iw)/2:(oh-ih)/2:black" -sws_flags lanczos -f yuv4mpegpipe \
		-an -sn \
		-y "${TEMP_DIR}"/"${VIDEO_PIPE}" 2>/dev/null &
	else
		die "Abort: No supported video transcoder detected." "3"
	fi

	if [ $? -ne 0 ]; then
		die "Abort: Failed to fill named pipe." "3"
	fi
}

# CreateVideoPipeStraightThrough(input file)
# Creates a named pipe for transcoded video to X standard
# Requirements: mplayer, mkfifo
#
# Relies on invoker to set the following VARIABLES:
# TEMP_DIR

CreateVideoPipeStraightThrough() {
	VIDEO_PIPE=$( tmp_random_name )
	echo "CreateVideoPipeStraightThrough named pipe is: "${VIDEO_PIPE}

	# Test for existence of videopipe already
	if [ -e "${TEMP_DIR}"/${VIDEO_PIPE} ]; then
		die "Abort: Named pipe file already exists." "3"
	else
	        mkfifo "${TEMP_DIR}"/${VIDEO_PIPE} || die "failed to create named pipe" "3"
	fi

	if command -v mplayer > /dev/null; then
	        mplayer -really-quiet -nosub -nosound -benchmark -vo yuv4mpeg:file="${TEMP_DIR}"/${VIDEO_PIPE} "${1}" &
	elif command -v ffmpeg > /dev/null; then
		ffmpeg -i "${1}" -f yuv4mpegpipe -an -sn -y "${TEMP_DIR}"/"${VIDEO_PIPE}" 2>/dev/null &
	else
		die "Abort: No video transcoder detected." "3"
	fi

	if [ "$?" -ne 0 ]; then
		die "Abort: Failed to fill named pipe." "3"
	fi
}

# DetectVideoCrop
# Sample 5% of video frames to estimate crop settings. Utilizes 99% confidence interval of final result.

# DestroyPipe(argument)
# Delete named pipes created by CreateAudipPipe or CreateVideoPipe*
#
# Relies on invoker to set the following VARIABLES:
# TEMP_DIR

DestroyPipe() {
	case "${1}" in
	audio)
		local NAMED_PIPE="${AUDIO_PIPE}"
		;;
	video)
		local NAMED_PIPE="${VIDEO_PIPE}"
		;;
	*)
		die "Abort: Unknown usage of DestroyPipe" "4"
		;;
	esac

	if [ -e "${TEMP_DIR}"/"${NAMED_PIPE}" ]; then
		rm "${TEMP_DIR}"/"${NAMED_PIPE}" || die "Abort: Failed to destroy named pipe." "4"
	fi
}

# EncodeAudio_FlacFlac(input file)
# Convert input file to Flac in the native Flac container
# Flac has no quality settings, only compressoin levels. Always use the best.
# Requirements: ffmpeg or flac
#
# Relies on invoker to set following VARIABLES:
# TEMP_DIR

EncodeAudio_FlacFlac() {
	# reference flac encoder needs coaxing to work with named pipes, and is picky about input formats - make it last.
	if command -v ffmpeg > /dev/null; then
		FLAC_SUPPORT=$( ffmpeg -codecs | grep -c "FLAC (Free Lossless Audio Codec)" )
		if [ "${FLAC_SUPPORT}" -eq 0 ]; then
			die "Abort: ffmpeg does not appear to support flac."
		fi

		CreateAudioPipe "${1}"
		ffmpeg -i "${TEMP_DIR}"/"${AUDIO_PIPE}" -acodec flac -compression_level 8 "${TEMP_DIR}"/audio.flac || die "ffmpeg failed" "2"
		DestroyPipe audio
	elif command -v flac > /dev/null; then
# uncomment if time is found to make this work with named pipes
#		flac --best "${TEMP_DIR}"/"${AUDIO_PIPE}" -o "${TEMP_DIR}"/audio.flac || die "Abort: flac failed." "2"
		flac --best "${INPUT}" -o "${TEMP_DIR}"/audio.flac || die "Abort: flac failed." "2"
	fi
}

# EncodeAudio_MP4AAC(input file)
# Converts input file to AAC and puts into an mp4 container.
# Requirements: common.sh.lib and neroAacEnc, faac, or ffmpeg
#
# Relies on invoker to set following VARIABLES:
# TEMP_DIR
#
# For audio files, the appropriate value of the following must also be set:
# FAAC_AAC_AUDIO_QUALITY_STANDALONE
# FFMPEG_AAC_AUDIO_QUALITY_STANDALONE
# LIBFDK_AAC_AUDIO_QUALITY_STANDALONE
# NEROAACENC_AAC_AUDIO_QUALITY_STANDALONE
#
# For video files, the following must be set:
# HAS_VIDEO
# FAAC_AAC_AUDIO_QUALITY_VIDEO
# FFMPEG_AAC_AUDIO_QUALITY_VIDEO
# LIBFDK_AAC_AUDIO_QUALITY_VIDEO
# NEROAACENC_AAC_AUDIO_QUALITY_VIDEO

EncodeAudio_MP4AAC() {
	# Test for audio encoders and set quality variable accordingly
	# Priority Order (descending): libfdk_aac, neroAacEnc, faac, ffmpeg
	# Build a named pipe and fill it with uncompressed WAV audio.
	# Have the audio encoder read from the pipe

	if command -v ffmpeg; then
		local AAC_SUPPORT=$( ffmpeg -codecs | grep -c "libfdk_aac" )
		if [ "${AAC_SUPPORT}" -ge 1 ]; then
			if [ -n "${HAS_VIDEO}" ] && [ "${HAS_VIDEO}" -ge 1 ]; then
				local AUDIO_QUALITY="${LIBFDK_AAC_AUDIO_QUALITY_VIDEO}"
			else
				local AUDIO_QUALITY="${LIBFDK_AAC_AUDIO_QUALITY_STANDALONE}"
			fi

			CreateAudioPipe "${1}"
			ffmpeg -i "${TEMP_DIR}"/"${AUDIO_PIPE}" -acodec libfdk_aac -vbr "${AUDIO_QUALITY}" "${TEMP_DIR}"/audio.mp4 || die "ffmpeg failed." "2"
		fi
	elif command -v neroAacEnc > /dev/null; then
		if [ -n "${HAS_VIDEO}" ] && [ "${HAS_VIDEO}" -ge 1 ]; then
			local AUDIO_QUALITY="${NEROAACENC_AAC_AUDIO_QUALITY_VIDEO}"
		else
			local AUDIO_QUALITY="${NEROAACENC_AAC_AUDIO_QUALITY_STANDALONE}"
		fi

		CreateAudioPipe "${1}"
		neroAacEnc -ignorelength -lc -q "${AUDIO_QUALITY}" -if "${TEMP_DIR}"/"${AUDIO_PIPE}" -of "${TEMP_DIR}"/audio.mp4 || die "neroAacEnc failed" "2"
	elif command -v faac > /dev/null; then
		if [ -n "${HAS_VIDEO}" ] && [ "${HAS_VIDEO}" -ge 1 ]; then
			local AUDIO_QUALITY="${FAAC_AUDIO_QUALITY_VIDEO}"
		else
			local AUDIO_QUALITY="${FAAC_AUDIO_QUALITY_STANDALONE}"
		fi

		CreateAudioPipe "${1}"
		faac -q "${AUDIO_QUALITY}" -o "${TEMP_DIR}"/audio.mp4 "${TEMP_DIR}"/"${AUDIO_PIPE}" || die "faac failed" "2"
	elif command -v ffmpeg > /dev/null; then
		if [ -n "${HAS_VIDEO}" ] && [ "${HAS_VIDEO}" -ge 1 ]; then
			local AUDIO_QUALITY="${FFMPEG_AAC_AUDIO_QUALITY_VIDEO}"
		else
			local AUDIO_QUALITY="${FFMPEG_AAC_AUDIO_QUALITY_STANDALONE}"
		fi

		AAC_SUPPORT=$( ffmpeg -codecs | grep -c "AAC (Advanced Audio Coding)" )
		if [ "${AAC_SUPPORT}" -eq 0 ]; then
			die "Abort: ffmpeg does not appear to support aac."
		fi

		CreateAudioPipe "${1}"
		# Uses libfaac as FFmpeg's aac encoder is experimental - is this true?
		ffmpeg -i "${TEMP_DIR}"/"${AUDIO_PIPE}" -acodec aac -aq "${AUDIO_QUALITY}" "${TEMP_DIR}"/audio.mp4 || die "ffmpeg failed" "2"
	else
		die "Abort: Failed to locate neroAacEnc, faac, or ffmpeg in your \$PATH." "2"
	fi

	DestroyPipe audio
}

# EncodeAudio_OggOpus(input file)
# Converts input file to Opus and puts into an ogg container.
# Requirements: ffmpeg, common.sh.lib

# Relies on invoker to set following VARIABLES:
# TEMP_DIR
#
# For audio files, one of the following must also be set:
# FFMPEG_OPUS_AUDIO_QUALITY_STANDALONE
#
# For video files, one of the following must also be set:
# HAS_VIDEO
# FFMPEG_OPUS_AUDIO_QUALITY_VIDEO

EncodeAudio_OggOpus() {
	if command -v ffmpeg > /dev/null; then
		local OPUS_SUPPORT=$( ffmpeg -codecs | grep -c "encoders: libopus" )
		if [ "${OPUS_SUPPORT}" -ge 1 ]; then
			if [ -n "${HAS_VIDEO}" ] && [ "${HAS_VIDEO}" -ge 1 ]; then
				local AUDIO_QUALITY="${FFMPEG_OPUS_AUDIO_QUALITY_VIDEO}"
			else
				local AUDIO_QUALITY="${FFMPEG_OPUS_AUDIO_QUALITY_STANDALONE}"
			fi
		else
			die "Abort: ffmpeg does not have support for libopus?" "2"
		fi

		CreateAudioPipe "${1}"
		ffmpeg -i "$TEMP_DIR"/"${AUDIO_PIPE}" -acodec libopus -b:a "${AUDIO_QUALITY}" "${TEMP_DIR}"/audio.opus || die "ffmpeg failed." "2"
	else
		die "Abort: Failed to locate ffmpeg in your \$PATH." "2"
	fi
	DestroyPipe audio
}

# EncodeAudio_OggVorbis(input file)
# Converts input file to Vorbis and puts into an ogg container.
# Requirements: vorbis-tools or ffmpeg, common.sh.lib
#
# Relies on invoker to set following VARIABLES:
# TEMP_DIR
#
# For audio files, the following must also be set:
# OGGENC_VORBIS_AUDIO_QUALITY_STANDALONE
# FFMPEG_VORBIS_AUDIO_QUALITY_STANDALONE
#
# For video files, the following must also be set:
# HAS_VIDEO
# OGGENC_VORBIS_AUDIO_QUALITY_VIDEO
# FFMPEG_VORBIS_AUDIO_QUALITY_VIDEO

EncodeAudio_OggVorbis() {
	if command -v oggenc > /dev/null; then
		if [ -n "${HAS_VIDEO}" ] && [ "${HAS_VIDEO}" -ge 1 ]; then
			local AUDIO_QUALITY="${OGGENC_VORBIS_AUDIO_QUALITY_VIDEO}"
		else
			local AUDIO_QUALITY="${OGGENC_VORBIS_AUDIO_QUALITY_STANDALONE}"
		fi

		CreateAudioPipe "${1}"
		oggenc -q "${AUDIO_QUALITY}" --ignorelength "${TEMP_DIR}"/"${AUDIO_PIPE}" -o "${TEMP_DIR}"/audio.ogg || die "oggenc failed" "2"
	elif command -v ffmpeg > /dev/null; then
		if [ -n "${HAS_VIDEO}" ] && [ "${HAS_VIDEO}" -ge 1 ]; then
			local AUDIO_QUALITY="${FFMPEG_VORBIS_AUDIO_QUALITY_VIDEO}"
		else
			local AUDIO_QUALITY="${FFMPEG_VORBIS_AUDIO_QUALITY_STANDALONE}"
		fi

		CreateAudioPipe "${1}"
		#NOTE: FFmpeg's vorbis implementation is experimental - using their libvorbis hook instead.
		ffmpeg -i "${TEMP_DIR}"/"${AUDIO_PIPE}" -acodec libvorbis -aq "${AUDIO_QUALITY}" "${TEMP_DIR}"/audio.ogg || die "ffmpeg failed" "2"
	else
		die "Abort: Failed to locate oggenc or ffmpeg in your \$PATH." "2"
	fi
	DestroyPipe audio
}

# GatherMediaInfo
# Store the output of a media query tool (midentify, ffprobe, etc) and set the tool to use for querying.

GatherMediaInfo() {
	if command -v ffprobe > /dev/null; then
		QUERY_MEDIA_TOOL=ffprobe
		MEDIA_INFO=$( ffprobe -show_streams "${INPUT}" 2>&1 )
	elif command -v midentify > /dev/null; then
		QUERY_MEDIA_TOOL=midentify
		MEDIA_INFO=$( midentify "${INPUT}" )
	elif command -v mplayer > /dev/null; then
		QUERY_MEDIA_TOOL=midentify
	# Adapted from midentify.sh by Tobias Diedrich <ranma+mplayer@tdiedrich.de>. License: GNU GPL
		MEDIA_INFO=$( mplayer -noconfig all -cache-min 0 -vo null -ao null -frames 0 -identify "${INPUT}" 2>/dev/null | sed -ne '/^ID_/ {
                         s/[]()|&;<>`'"'"'\\!$" []/\\&/g;p
                        }')
	# End adaptation of midentify.sh
	elif command -v ffmpeg > /dev/null; then
		QUERY_MEDIA_TOOL=ffmpeg
		MEDIA_INFO=$( ffmpeg -i "${INPUT}" 2>&1 )
	else
		die "Abort: No known program found to find media stream information." "4"
	fi
}

# NormalizeAudio

# QueryAudioChannels(input file)
# Inspect input file for the number of audio channels
# ASSUMES ONE AUDIO STREAM
# Uses: mplayer or FFprobe or ...

QueryAudioChannels() {
	case "${QUERY_MEDIA_TOOL}" in
	ffprobe)
		local AUDIO_CHANNELS=$( echo "${MEDIA_INFO}" | grep "channels=" | cut -d '=' -f 2 )
		;;
	midentify)
		local AUDIO_CHANNELS=$( echo "${MEDIA_INFO}" | grep ID_AUDIO_NCH | cut -d '=' -f 2 )
		;;
	*)
		die "Abort; Unknown option passed to QueryAudioChannels" "4"
		;;
	esac
	echo "${AUDIO_CHANNELS}"
}

# QueryAudioCodec
# Determine the audio codec used in a stream
#
# MUST RUN: GatherMediaInfo

QueryAudioCodec() {
	case "${QUERY_MEDIA_TOOL}" in
		ffprobe|ffmpeg)
			local AUDIO_CODEC=$( echo "${MEDIA_INFO}" | sed -e '/Stream/!d' -e '/Audio/!d' | cut -d ' ' -f 8 )
			;;
		midentify)
			local AUDIO_CODEC=$( echo "${MEDIA_INFO}" | grep "ID_AUDIO_CODEC" | cut -d '=' -f 2 | tr -d 'ff' )
			;;
		*)
			die "Abort: Unknown option passed to QueryAudioCodec." "4"
			;;
	esac
	echo "${AUDIO_CODEC}"
}

# QueryAudioStreamMap(input file)

# QueryVideoDisplayAspectRatio
# Query a video file to determine its display aspect ratio
#
# MUST RUN: GatherMediaInfo

QueryVideoDisplayAspectRatio() {
	case "${QUERY_MEDIA_TOOL}" in
		ffprobe)
			local VIDEO_DISPLAY_ASPECT_RATIO=$( echo "${MEDIA_INFO}" | grep display_aspect_ratio | head -n 1 | cut -d '=' -f 2 )
			;;
		midentify)
			local VIDEO_DISPLAY_ASPECT_RATIO=$( echo "${MEDIA_INFO}" | grep ID_VIDEO_ASPECT | cut -d '=' -f 2 )
			if [ "${VIDEO_DISPLAY_ASPECT_RATIO}" -eq 1.7778 ]; then
				local VIDEO_DISPLAY_ASPECT_RATIO="16/9"
			elif [ "${VIDEO_DISPLAY_ASPECT_RATIO}" -eq 1.3333 ]; then
				local VIDEO_DISPLAY_ASPECT_RATIO="4/3"
			else
				echo "NOTICE: You have a video with an odd aspect resolution. Is it genuine? Email the author to include it."
			fi
			;;
		ffmpeg)
			local VIDEO_DISPLAY_ASPECT_RATIO=$( echo "${MEDIA_INFO}" | grep Stream | grep Video | cut -d ',' -f 3 | sed -e 's/\ /-/g' -e 's/.$//' | cut -d '-' -f 6 | tr '\:' / )
			;;
		*)
			die "Abort: Unknown option passed to QueryVideoDisplayAspectRatio." "4"
			;;
		esac
		echo "${VIDEO_DISPLAY_ASPECT_RATIO}"
}

# QueryVideoDuration (input file)
# Query a video file to determine it's duration. Return format in HH:MM:SS.Microseconds. Drop -sexagesimal to be just seconds.

QueryVideoDuration() {
	local VIDEO_DURATION=$( ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 -sexagesimal "${1}" )

	echo "${VIDEO_DURATION}"
}

# QueryVideoFPS
# Query a video file to determine its Frames per Second (FPS)
#
# MUST RUN: GatherMediaInfo

QueryVideoFPS() {
	case "${QUERY_MEDIA_TOOL}" in
		ffprobe)
			local VIDEO_FPS=$( echo "${MEDIA_INFO}" | grep r_frame_rate | head -n 1 | cut -d '=' -f 2 )
			;;
		midentify)
			local VIDEO_FPS=$( echo "${MEDIA_INFO}" | grep ID_VIDEO_FPS | cut -d '=' -f 2 )
			;;
		ffmpeg)
			echo "INFO: ffmpeg rounds the FPS, results may be sub-par."
			local VIDEO_FPS=$( echo "${MEDIA_INFO}" | grep Stream | grep Video | cut -d ' ' -f 21 )
			;;
		*)
			die "Abort: Unknown option passed to QueryVideoFPS." "4"
			;;
	esac
	echo "${VIDEO_FPS}"
}

# QueryVideoHeight
# Query a video file to determine its display height
#
# MUST RUN: GatherMediaInfo

QueryVideoHeight() {
	case "${QUERY_MEDIA_TOOL}" in
		ffprobe)
			local VIDEO_HEIGHT=$( echo "${MEDIA_INFO}" | grep height | head -n 1 | cut -d '=' -f 2 )
			;;
		midentify)
			local VIDEO_HEIGHT=$( echo "${MEDIA_INFO}" | grep ID_VIDEO_HEIGHT | cut -d '=' -f 2 )
			;;
		ffmpeg)
			local VIDEO_HEIGHT=$( echo "${MEDIA_INFO}" | grep Stream | grep Video | cut -d ',' -f 3 | tr " " - | cut -d '-' -f 2 | cut -d 'x' -f 2 )
			;;
		*)
			die "Abort: Unknown option passed to QueryVideoHeight." "4"
			;;
	esac
	echo "${VIDEO_HEIGHT}"
}

# QueryVideoSampleAspectRatio
# Query a video file to determine its sample aspect ratio
#
# MUST RUN: GatherMediaInfo

QueryVideoSampleAspectRatio() {
	case "${QUERY_MEDIA_TOOL}" in
		ffprobe)
			local VIDEO_SAMPLE_ASPECT_RATIO=$( echo "${MEDIA_INFO}" | grep sample_aspect_ratio | head -n 1 | cut -d '=' -f 2 )
			;;
		*)
			die "Abort: Unknown option passed to ""${0}""." "4"
			;;
	esac
	echo "${VIDEO_SAMPLE_ASPECT_RATIO}"
}

# QueryVideoWidth
# Query a video file to determine its display width
#
# MUST RUN: GatherMediaInfo

QueryVideoWidth() {
	case "${QUERY_MEDIA_TOOL}" in
		ffprobe)
			local VIDEO_WIDTH=$( echo "${MEDIA_INFO}" | grep width | head -n 1 | cut -d '=' -f 2 )
			;;
		midentify)
			local VIDEO_WIDTH=$( echo "${MEDIA_INFO}" | grep ID_VIDEO_WIDTH | cut -d '=' -f 2 )
			;;
		ffmpeg)
			local VIDEO_WIDTH=$( echo "${MEDIA_INFO}" | grep Stream | grep Video | cut -d ',' -f 3 | tr " " - | cut -d '-' -f 2 | cut -d 'x' -f 1 )
			;;
		*)
			die "Abort: Unknown option passed to QueryVideoWidth." "4"
			;;
	esac
	echo "${VIDEO_WIDTH}"
}

# TestForAudio(input file)
# Check a file for the presence of an audio stream
# Uses: ffprobe, midentify, mplayer, or ffmpeg
#
# MUST RUN: GatherMediaInfo

TestForAudio() {
	case "${QUERY_MEDIA_TOOL}" in
		ffprobe) 
			local AUDIO_TEST=$( echo "${MEDIA_INFO}" | grep -c codec_type=audio )
			;;
		midentify)
			local AUDIO_TEST=$( echo "${MEDIA_INFO}" | grep -c ID_AUDIO )
			;;
		ffmpeg)
			local AUDIO_TEST=$( echo "${MEDIA_INFO}" | grep -c Audio )
			;;
		*)
			die "Abort: Unknown option passed to TestForAudio." "4"
			;;
	esac
	echo "${AUDIO_TEST}"
}

# TestForVideo(input file)
# Check a file for the presence of a video stream
# Uses: ffprobe, midentify, mplayer, or ffmpeg
#
# MUST RUN: GatherMediaInfo

TestForVideo() {
	case "${QUERY_MEDIA_TOOL}" in
		ffprobe) 
			local VIDEO_TEST=$( echo "${MEDIA_INFO}" | grep -c codec_type=video )
			;;
		midentify)
			local VIDEO_TEST=$( echo "${MEDIA_INFO}" | grep -c ID_VIDEO )
			;;
		ffmpeg)
			local VIDEO_TEST=$( echo "${MEDIA_INFO}" | grep -c Video )
			;;
		*)
			die "Abort: Unkown option passed to TestForVideo." "4"
			;;
	esac
	echo "${VIDEO_TEST}"
}
