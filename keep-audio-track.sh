#!/bin/bash
# Usage: ./keep-audio-track.sh <audio-track-id> <input-dir> <output-dir>
# Example: ./keep-audio-track.sh 2 input output

# Check for 3 arguments
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <audio-track-id> <input-dir> <output-dir>"
  exit 1
fi

KEEP_AUDIO_ID="$1"
INPUT_DIR="$2"
OUTPUT_DIR="$3"

# Validate input directory
if [ ! -d "$INPUT_DIR" ]; then
  echo "Error: Input directory '$INPUT_DIR' does not exist."
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Process all MKV files in input directory
for file in "$INPUT_DIR"/*.mkv; do
  [ -e "$file" ] || continue # skip if no files match
  filename=$(basename "$file")
  output_file="$OUTPUT_DIR/${filename%.*}_audio${KEEP_AUDIO_ID}.mkv"

  echo "Processing: $filename"

  # Keep only the specified audio track
  mkvmerge -o "$output_file" --audio-tracks "$KEEP_AUDIO_ID" "$file"

  if [ $? -eq 0 ]; then
    echo "✔ Saved: $output_file"
  else
    echo "❌ Error processing $filename"
  fi
done

echo "Done."
