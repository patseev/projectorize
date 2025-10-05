#!/bin/bash

# Usage: ./process_mkvs.sh <input_directory> <output_directory>

# --- Argument validation ---
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_directory> <output_directory>"
  exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"

# Ensure the input directory exists
if [ ! -d "$INPUT_DIR" ]; then
  echo "Error: Input directory '$INPUT_DIR' not found."
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Process all MKV files in the input directory
shopt -s nullglob
for INPUT in "$INPUT_DIR"/*.mkv; do
  [ -e "$INPUT" ] || {
    echo "No MKV files found in '$INPUT_DIR'."
    exit 0
  }

  filename=$(basename "$INPUT")
  name="${filename%.*}"
  ext="${filename##*.}"
  OUTPUT="${OUTPUT_DIR}/${name}_no_dolby.${ext}"

  echo "--------------------------------------"
  echo "Processing: $filename"

  # Extract the codec of the first audio stream
  codec=$(ffprobe -v error -select_streams a:0 \
    -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 "$INPUT")

  echo "Main audio codec: $codec"

  # If Dolby, convert to AAC; otherwise copy file
  if [[ "$codec" == "ac3" || "$codec" == "eac3" ]]; then
    echo "Dolby audio detected. Converting to AAC..."
    ffmpeg -hide_banner -loglevel error -i "$INPUT" -c:v copy -c:a aac -b:a 192k "$OUTPUT"
  else
    echo "Non-Dolby audio detected. Copying file..."
    cp "$INPUT" "$OUTPUT"
  fi

  echo "Output saved to: $OUTPUT"
done
echo "--------------------------------------"
echo "Processing complete. Files saved in: $OUTPUT_DIR"
