#!/bin/bash
# Usage: ./replace-audio-with-mka.sh <video.mkv> <audio.mka>

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <video.mkv> <audio.mka>"
  exit 1
fi

VIDEO="$1"
AUDIO="$2"

# Validate input files
if [ ! -f "$VIDEO" ]; then
  echo "Error: Video file '$VIDEO' not found."
  exit 1
fi

if [ ! -f "$AUDIO" ]; then
  echo "Error: Audio file '$AUDIO' not found."
  exit 1
fi

# Build output filename
base_name=$(basename "$VIDEO" .mkv)
output="${base_name}_with_mka.mkv"

echo "Muxing video from '$VIDEO' with audio from '$AUDIO'..."
mkvmerge -o "$output" -A "$VIDEO" --default-track 0:yes "$AUDIO"

if [ $? -eq 0 ]; then
  echo "✅ Done. Output saved to: $output"
else
  echo "❌ mkvmerge failed."
fi
