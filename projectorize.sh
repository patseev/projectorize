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

  # Mux the video with the external audio. The -A option removes existing audio tracks.
  mkvmerge -o "$OUT_DIR/$base" -A "$video" "$audio"
done

echo "Muxing complete. Check the '$OUT_DIR' directory for the output files."
