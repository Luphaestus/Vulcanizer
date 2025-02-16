#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <root_directory> <grep_pattern>"
    exit 1
fi

root_directory=$1
grep_pattern='?'

# Function to process directories recursively
process_directory() {
    local dir=$1

    echo "Processing directory: $dir"
    ls -Z "$dir" 2>/dev/null | grep "$grep_pattern"

    # Loop through all items in the directory
    for item in "$dir"/*; do
        if [ -d "$item" ]; then
            # If the item is a directory, process it recursively
            process_directory "$item"
        fi
    done
}

# Start processing from the root directory
process_directory "$root_directory"
