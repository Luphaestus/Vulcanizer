Mount(){

  local image=$1
  local mount_dir=$2

  UI "Mounting: $(basename "$image" | cut -d '.' -f 1)"

  if mountpoint -q "$mount_dir"; then
      UI "f"
      UI "!$(basename "$image" | cut -d '.' -f 1) is already mounted."

      UI "Unmounting: $(basename "$image" | cut -d '.' -f 1)"
       sudo umount $mount_dir 
       rm -rf $mount_dir 
      UI "d"
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