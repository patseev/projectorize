#!/bin/bash
# Usage: ./replace-audio-directory.sh <video_directory> <audio_directory> [output_directory]
# Matches MKV files with audio files by episode number pattern

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <video_directory> <audio_directory> [output_directory]"
  echo "If output_directory is not specified, files are saved in the video directory"
  exit 1
fi

VIDEO_DIR="$1"
AUDIO_DIR="$2"
OUTPUT_DIR="${3:-$VIDEO_DIR}"

# Validate directories
if [ ! -d "$VIDEO_DIR" ]; then
  echo "Error: Video directory '$VIDEO_DIR' not found."
  exit 1
fi

if [ ! -d "$AUDIO_DIR" ]; then
  echo "Error: Audio directory '$AUDIO_DIR' not found."
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Extract episode number from filename
extract_episode_number() {
  local filename="$1"
  # Try various patterns: E01, EP01, Episode01, 01, [01], - 01, etc.
  echo "$filename" | grep -oE '[0-9]+' | head -1
}

processed=0
failed=0

# Process each MKV file
for video in "$VIDEO_DIR"/*.mkv; do
  [ -f "$video" ] || continue

  video_basename=$(basename "$video")
  episode_num=$(extract_episode_number "$video_basename")

  if [ -z "$episode_num" ]; then
    echo "Warning: Could not extract episode number from '$video_basename', skipping."
    continue
  fi

  # Find matching audio file
  audio_file=""
  while IFS= read -r -d '' audio; do
    audio_basename=$(basename "$audio")
    audio_episode=$(extract_episode_number "$audio_basename")

    if [ "$audio_episode" = "$episode_num" ]; then
      audio_file="$audio"
      break
    fi
  done < <(find "$AUDIO_DIR" -maxdepth 1 -type f \( -name "*.mka" -o -name "*.aac" -o -name "*.ac3" -o -name "*.mp3" -o -name "*.flac" -o -name "*.opus" -o -name "*.m4a" \) -print0 2>/dev/null)

  if [ -z "$audio_file" ]; then
    echo "Warning: No matching audio file found for episode $episode_num ($video_basename), skipping."
    ((failed++))
    continue
  fi

  # Build output filename
  output_name="${video_basename%.mkv}_rus.mkv"
  output_path="$OUTPUT_DIR/$output_name"

  echo "Processing episode $episode_num:"
  echo "  Video: $video_basename"
  echo "  Audio: $(basename "$audio_file")"

  mkvmerge -o "$output_path" -A "$video" --default-track 0:yes "$audio_file"

  if [ $? -eq 0 ]; then
    echo "  Done: $output_name"
    ((processed++))
  else
    echo "  Failed!"
    ((failed++))
  fi
  echo ""
done

echo "========================================="
echo "Processed: $processed, Failed: $failed"
