#!/bin/bash
# Usage function to display how to run the script.
usage() {
  echo "Usage: $0 <MKV_DIR> <MKA_DIR> <OUT_DIR>"
  echo "Example: $0 mkv mka out"
  exit 1
}

# Check if three parameters were provided.
if [ "$#" -ne 3 ]; then
  usage
fi

# Assign command-line arguments to variables.
MKV_DIR="$1"
MKA_DIR="$2"
OUT_DIR="$3"

# Create the output directory if it doesn't exist.
mkdir -p "$OUT_DIR"

# Check for required tools.
for tool in find sort ffprobe ffmpeg mkvmerge; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: $tool is not installed."
    exit 1
  fi
done

# Initialize arrays.
mkv_files=()
mka_files=()

# Read MKV files into the mkv_files array.
while IFS= read -r file; do
  mkv_files+=("$file")
done < <(find "$MKV_DIR" -maxdepth 1 -type f -name "*.mkv" | sort)

# Read MKA files into the mka_files array.
while IFS= read -r file; do
  mka_files+=("$file")
done < <(find "$MKA_DIR" -maxdepth 1 -type f -name "*.mka" | sort)

# Check if both arrays have the same number of files.
if [ "${#mkv_files[@]}" -ne "${#mka_files[@]}" ]; then
  echo "Error: The number of MKV files (${#mkv_files[@]}) does not match the number of MKA files (${#mka_files[@]})."
  exit 1
fi

# Loop over the paired files.
for i in "${!mkv_files[@]}"; do
  video="${mkv_files[i]}"
  audio="${mka_files[i]}"

  # Use the original MKV filename for the output.
  base=$(basename "$video")

  echo "Processing '$base': using audio file '$(basename "$audio")'."

  # Check the audio codec of the first audio stream using ffprobe.
  codec=$(ffprobe -v error -select_streams a:0 \
    -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 "$audio")

  audio_to_use="$audio"
  tmp_audio=""

  # If the audio codec is Dolby (ac3 or eac3), convert it to AAC.
  if [[ "$codec" == "ac3" || "$codec" == "eac3" ]]; then
    echo "  Detected Dolby audio codec ($codec). Converting to AAC..."
    # Create a temporary file with a proper extension.
    tmp_audio=$(mktemp /tmp/tmp_audio.XXXXXX.mka)
    if [ -z "$tmp_audio" ]; then
      echo "  Error: Could not create a temporary file."
      continue
    fi
    # Convert audio using ffmpeg and force the output format to Matroska.
    ffmpeg -y -i "$audio" -c:a aac -b:a 192k -f matroska "$tmp_audio" </dev/null
    if [ $? -ne 0 ]; then
      echo "  Error: Failed to convert audio. Skipping '$base'."
      [ -n "$tmp_audio" ] && rm -f "$tmp_audio"
      continue
    fi
    audio_to_use="$tmp_audio"
  fi

  # Mux the video with the (possibly converted) audio. The -A option removes existing audio tracks.
  mkvmerge -o "$OUT_DIR/$base" -A "$video" "$audio_to_use"

  # Clean up temporary file if one was created.
  if [ -n "$tmp_audio" ]; then
    rm -f "$tmp_audio"
  fi
done

echo "Muxing complete. Check the '$OUT_DIR' directory for the output files."
