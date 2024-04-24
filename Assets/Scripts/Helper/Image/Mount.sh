Mount(){
  local image=$1
  local mount_dir=$2

  if Is_Extracted "$mount_dir" ; then
    return 0
  fi

  if [[ ! "$image" =~ \.img$ ]]; then
    UI "!!Mount: $image_path must be a .img"
    exit 1
  fi


  UI "Mounting: $(basename "$image" | cut -d '.' -f 1)"
  if mountpoint -q "$mount_dir"; then
      UI "f"
      UI "!$(basename "$image" | cut -d '.' -f 1) is already mounted."
      Unmount $mount_dir
      rm -rf $mount_dir
      UI "Mounting: $(basename "$image" | cut -d '.' -f 1)"
  fi

  current_size=$(du -m "$1" | awk '{print $1}')
  e2fsck -fa $1 >/dev/null

  fixed_size=500
  new_size=$((current_size + fixed_size))
  resize2fs $1 ${new_size}M  2>&1 | grep -v resize2fs >/dev/null
  mkdir -p "$2" >/dev/null
  sudo mount -o rw $1 $2
  UI "d"
}