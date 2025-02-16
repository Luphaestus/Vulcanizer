#!/bin/bash

# Source directory
FIXES_DIR="fixes"

# Destination directory
MOUNTED_VENDOR_DIR="/mnt/mydisk/android/VulcaniverV2/files/vendor"

# Copy files from fixes to mounted-vendor while preserving directory structure
copy_files() {
    find "$FIXES_DIR" -type f -exec sh -c '
        src_path="$1"
        dest_path="$2/${src_path#*/}"
        mkdir -p "$(dirname "$dest_path")"
        cp -a "$src_path" "$dest_path"
    ' sh {} "$MOUNTED_VENDOR_DIR" \;
}

# Execute the function
copy_files

echo "Files copied from fixes to mounted-vendor."
