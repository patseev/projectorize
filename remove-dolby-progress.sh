#!/bin/bash
# Usage: ./process_video_with_progress.sh /path/to/video.mkv

# Check that exactly one argument is provided.
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <path-to-video>"
  exit 1
fi

INPUT="$1"

# Check that the input file exists.
if [ ! -f "$INPUT" ]; then
  echo "Error: File '$INPUT' not found."
  exit 1
fi

# Construct the output filename: same directory, same base name with _no_dolby appended.
dir=$(dirname "$INPUT")
filename=$(basename "$INPUT")
name="${filename%.*}"
ext="${filename##*.}"
OUTPUT="${dir}/${name}_no_dolby.${ext}"

# Get the codec of the first audio stream.
codec=$(ffprobe -v error -select_streams a:0 \
  -show_entries stream=codec_name \
  -of default=noprint_wrappers=1:nokey=1 "$INPUT")
echo "Main audio codec: $codec"

# Function to run ffmpeg conversion with a progress bar.
convert_with_progress() {
  # Get the total duration (in seconds) using ffprobe.
  DURATION=$(ffprobe -v error -select_streams v:0 \
    -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$INPUT")
  # Convert duration to an integer (seconds).
  DURATION=${DURATION%.*}
  if [ -z "$DURATION" ] || [ "$DURATION" -eq 0 ]; then
    echo "Could not determine video duration."
    exit 1
  fi

  echo "Video duration: ${DURATION} seconds"

  # Start ffmpeg conversion. We use -y to overwrite the output.
  # The conversion copies video and converts audio to AAC.
  ffmpeg -i "$INPUT" -c:v copy -c:a aac -b:a 192k "$OUTPUT" -y 2>&1 |
    while IFS= read -r line; do
      # Look for a line containing "time=" (ffmpeg prints this repeatedly).
      if [[ $line =~ time=([0-9:.]+) ]]; then
        current_time=${BASH_REMATCH[1]}
        # Convert current_time (format HH:MM:SS.mmm) to seconds.
        IFS=: read h m s <<<"$current_time"
        # Remove any potential carriage return from s.
        s=$(echo "$s" | tr -d '\r')
        # Calculate seconds (using awk for floating point arithmetic).
        secs=$(awk -v h="$h" -v m="$m" -v s="$s" 'BEGIN { printf "%.2f", h*3600 + m*60 + s }')
        # Compute progress percentage.
        perc=$(awk -v secs="$secs" -v dur="$DURATION" 'BEGIN { printf "%.2f", (secs/dur)*100 }')
        # Build a simple text progress bar.
        bar_length=50
        # Compute number of hashes.
        hashes=$(awk -v perc="$perc" -v bar_length="$bar_length" 'BEGIN { printf "%d", (perc/100)*bar_length }')
        spaces=$((bar_length - hashes))
        # Build the hash and space strings.
        bar=$(printf "%0.s#" $(seq 1 $hashes))
        empty=$(printf "%0.s " $(seq 1 $spaces))
        # Print progress (using carriage return to update in place).
        printf "\rProgress: [${bar}${empty}] %s%%" "${perc}"
      fi
    done
  echo -e "\nConversion complete."
}

# If main audio is Dolby, convert audio; otherwise, simply copy the file.
if [[ "$codec" == "ac3" || "$codec" == "eac3" ]]; then
  echo "Dolby audio detected. Converting audio to AAC..."
  convert_with_progress
else
  echo "Main audio is not Dolby. Copying file without conversion..."
  cp "$INPUT" "$OUTPUT"
fi

echo "Output saved to: $OUTPUT"
