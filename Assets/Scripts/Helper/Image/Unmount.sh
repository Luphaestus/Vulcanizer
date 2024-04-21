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