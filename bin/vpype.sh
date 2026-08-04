#!/bin/sh

# Check if an input filename was provided
if [ -z "$1" ]; then
    echo "Please pass a file to be optimized: $0 <input_filename>"
    exit 1
fi

FILENAME=$1

# Check if the file exists in the current working directory
if [ ! -f "./$FILENAME" ]; then
    echo "Error: File '$FILENAME' not found in the current directory."
    exit 1
fi

# Extract the base name and the extension
BASENAME="${FILENAME%.*}"
EXTENSION="${FILENAME##*.}"

# Generate the output filename
OUTPUT_FILENAME="${BASENAME}-optimized.${EXTENSION}"

docker run --rm -v "$(pwd):/workspace" vpype-cli \
    read --no-crop "$FILENAME" \
    splitall \
    linemerge \
    linesimplify \
    linesort \
    write "$OUTPUT_FILENAME"
