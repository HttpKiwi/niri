#!/bin/bash

# The script takes at least one argument: the path to the image or video.
# All subsequent arguments are passed to matugen.
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_file> [matugen_options]"
    exit 1
fi

ORIGINAL_FILE="$1"
shift # The rest of the arguments are for matugen

BLURRED_CACHE_DIR="$HOME/Pictures/blurred"
TEMP_FRAME="/tmp/matugen_source_frame.png"

# --- Determine Source Image ---
# If the input is a video, extract a frame to use as the source for everything.
# Otherwise, use the original file.
INPUT_SOURCE="$ORIGINAL_FILE"
MIMETYPE=$(file --mime-type -b "$ORIGINAL_FILE")
if [[ $MIMETYPE == video/* ]]; then
    echo "Video file detected. Extracting a frame to use as the source."
    ffmpeg -i "$ORIGINAL_FILE" -vframes 1 -an -s hd720 "$TEMP_FRAME" -y
    INPUT_SOURCE="$TEMP_FRAME"
fi

# --- Blurring and Caching ---
# Create the cache directory if it doesn't exist
mkdir -p "$BLURRED_CACHE_DIR"

# Get the filename from the original file path
FILENAME=$(basename -- "$ORIGINAL_FILE")
FILENAME_NO_EXT="${FILENAME%.*}"

# Define the path for the blurred image
BLURRED_IMAGE_PATH="$BLURRED_CACHE_DIR/${FILENAME_NO_EXT}_blurred.png"

if [ -f "$BLURRED_IMAGE_PATH" ]; then
    echo "Blurred image already exists in cache: $BLURRED_IMAGE_PATH"
else
    echo "Creating blurred version and saving to: $BLURRED_IMAGE_PATH"
    # Use [0] to handle animated images (harmless on static ones)
    magick "$INPUT_SOURCE[0]" -scale 10% -blur 0x2.5 -resize 1000% "$BLURRED_IMAGE_PATH"
fi

# --- Run Matugen ---
echo "Running matugen with your options..."
matugen image "$INPUT_SOURCE" "$@"

# --- Set Wallpapers ---
echo "Setting main wallpaper..."
swww img "$ORIGINAL_FILE" --transition-type center --namespace wallpaper

echo "Setting blurred wallpaper for overview..."
swww img "$BLURRED_IMAGE_PATH" --namespace=overview

# --- Cleanup ---
if [ -f "$TEMP_FRAME" ]; then
    rm "$TEMP_FRAME"
fi

echo "Done."
