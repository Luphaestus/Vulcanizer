Unmount_All() {
  local target_dir="$1"

  if [ ! -d "$target_dir" ]; then
    echo "Error: Target directory '$target_dir' does not exist."
    return 1
  fi

  while IFS= read -r -d '' dir; do
    sudo umount "$dir"
    if [ $? -eq 0 ]; then
      echo "Successfully unmounted: $dir"
    else
      echo "Failed to unmount: $dir"
    fi
  done < <(find "$target_dir" -type d -print0 | sort -r)
}

Unmount() {
  local mounted_dir=$1
  local image_path=$2

  if Is_Extracted "$mounted_dir"; then
    return 0
  fi

  if mountpoint -q "$mounted_dir"; then
    if [ ! -d "$mounted_dir" ]; then
      UI "!!Unmount: $mounted_dir not a valid directory."
      exit 1
    fi

    UI "Unmounting: $(basename $mounted_dir)"
    sudo umount $mounted_dir
    rm -rf $mounted_dir
    if [ -n "$image_path" ]; then
      if [[ ! "$image_path" =~ \.img$ ]]; then
        UI "!!Unmount: $image_path must be a .img"
        exit 1
      fi
      e2fsck -fa "$image_path" >/dev/null
      resize2fs -M "$image_path" 2>&1 | grep -v resize2fs >/dev/null
    fi
    UI "d"
  fi

}