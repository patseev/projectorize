#!/bin/bash
# projectorize-with-selected-track.sh
#
# Usage: ./projectorize-with-selected-track.sh <track-number> <input-directory> <output-directory>
#
# For every MKV file in the input directory:
#   1. Unsets default flag on all tracks.
#   2. Sets the specified track (by track-number) as default.
#   3. Checks if the specified track is Dolby (AC3 or E-AC3).
#      - If yes, converts that track to AAC (while copying all other streams).
#   4. Saves the output file with a _projectorized suffix in the output directory.

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <track-number> <input-directory> <output-directory>"
  exit 1
fi

TRACK_N="$1"
INPUT_DIR="$2"
OUTPUT_DIR="$3"

# Check if input directory exists.
if [ ! -d "$INPUT_DIR" ]; then
  echo "Error: Input directory '$INPUT_DIR' not found."
  exit 1
fi

# Create output directory if it doesn't exist.
mkdir -p "$OUTPUT_DIR"

# Process each MKV file in the input directory.
for file in "$INPUT_DIR"/*.mkv; do
  # Skip if no files found.
  [ -e "$file" ] || continue

  echo "----------------------------------------"
  echo "Processing file: $file"

  # Get all track IDs using mkvmerge.
  track_ids=()
  while IFS= read -r line; do
    if [[ $line =~ Track\ ID\ ([0-9]+): ]]; then
      id="${BASH_REMATCH[1]}"
      track_ids+=("$id")
    fi
  done < <(mkvmerge -i "$file")

  if [ ${#track_ids[@]} -eq 0 ]; then
    echo "No tracks found in $file. Skipping."
    continue
  fi

  # Unselect default flag on all tracks.
  cmd=(mkvpropedit "$file")
  for id in "${track_ids[@]}"; do
    cmd+=(--edit "track:$id" --set "flag-default=0")
  done
  echo "Unselecting default flags for all tracks..."
  "${cmd[@]}"

  # Now mark the selected track as default.
  echo "Setting track $TRACK_N as default..."
  mkvpropedit "$file" --edit "track:$TRACK_N" --set "flag-default=1"

  # Check if the selected track is Dolby.
  track_line=$(mkvmerge -i "$file" | grep "Track ID $TRACK_N:")
  if [ -z "$track_line" ]; then
    echo "Warning: Track $TRACK_N not found in $file. Skipping further actions."
    continue
  fi

  is_dolby=0
  if echo "$track_line" | grep -iqE "ac3|eac3"; then
    is_dolby=1
    echo "Track $TRACK_N is Dolby."
  else
    echo "Track $TRACK_N is not Dolby."
  fi

  # Build the output filename with _projectorized suffix in the output directory.
  base=$(basename "$file")
  name="${base%.*}"
  ext="${base##*.}"
  output="${OUTPUT_DIR}/${name}_projectorized.${ext}"

  if [ $is_dolby -eq 1 ]; then
    echo "Converting track $TRACK_N from Dolby to AAC..."
    # Note: This assumes that the ffmpeg audio stream order corresponds with track numbers.
    # Often, video is stream 0, so audio stream index for selected track = TRACK_N - 1.
    ffmpeg_audio_index=$((TRACK_N - 1))
    # Convert the selected audio track while copying all other streams.
    ffmpeg -i "$file" -map 0 -c:v copy -c:a copy -c:a:$ffmpeg_audio_index aac -b:a 192k "$output" -y
    if [ $? -eq 0 ]; then
      echo "Conversion complete. Output saved as: $output"
    else
      echo "Error during conversion for $file."
    fi
  else
    echo "No conversion needed. Copying file..."
    cp "$file" "$output"
    echo "File copied to: $output"
  fi

  echo "Finished processing $file"
done

echo "All files processed."
