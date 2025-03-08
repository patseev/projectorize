#!/bin/bash

# Check if a video file was provided.
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <video-file>"
  exit 1
fi

VIDEO="$1"

# Ensure the video file exists.
if [ ! -f "$VIDEO" ]; then
  echo "Error: File not found: $VIDEO"
  exit 1
fi

# Extract the codec name of the first audio stream.
codec=$(ffprobe -v error -select_streams a:0 \
  -show_entries stream=codec_name \
  -of default=noprint_wrappers=1:nokey=1 "$VIDEO")

if [ -z "$codec" ]; then
  echo "No audio streams found in $VIDEO."
  exit 0
fi

# Check if the codec is a Dolby format.
if [[ "$codec" == "ac3" || "$codec" == "eac3" ]]; then
  echo "Dolby audio detected as main track: $codec"
else
  echo "Main audio track is not Dolby (codec: $codec)"
fi
