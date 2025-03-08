#!/bin/bash

# Check if a video file was provided.
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path-to-video>"
  exit 1
fi

INPUT="$1"

# Ensure the video file exists.
if [ ! -f "$INPUT" ]; then
  echo "Error: File '$INPUT' not found."
  exit 1
fi

# Construct the output file name by appending _no_dolby before the extension.
dir=$(dirname "$INPUT")
filename=$(basename "$INPUT")
name="${filename%.*}"
ext="${filename##*.}"
OUTPUT="${dir}/${name}_no_dolby.${ext}"

# Use ffprobe to extract the codec of the first audio stream.
codec=$(ffprobe -v error -select_streams a:0 \
  -show_entries stream=codec_name \
  -of default=noprint_wrappers=1:nokey=1 "$INPUT")

echo "Main audio codec: $codec"

# Check if the main audio track is Dolby (ac3 or eac3).
if [[ "$codec" == "ac3" || "$codec" == "eac3" ]]; then
  echo "Dolby audio detected. Converting audio to AAC and copying video..."
  # Convert the audio to AAC while copying the video stream.
  ffmpeg -i "$INPUT" -c:v copy -c:a aac -b:a 192k "$OUTPUT"
else
  echo "Main audio is not Dolby. Copying file without conversion..."
  cp "$INPUT" "$OUTPUT"
fi

echo "Output saved to: $OUTPUT"
