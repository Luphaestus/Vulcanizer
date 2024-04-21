Mount(){

  local image=$1
  local mount_dir=$2
  local dry_run=$3

  UI "Mounting: $(basename "$image" | cut -d '.' -f 1)"

  if mountpoint -q "$mount_dir"; then
      UI "f"
      UI "!$(basename "$image" | cut -d '.' -f 1) is already mounted."

      UI "Unmounting: $(basename "$image" | cut -d '.' -f 1)"
      Dry_Run sudo umount $mount_dir $dry_run
      Dry_Run rm -rf $mount_dir $dry_run
      UI "d"
      UI "Mounting: $(basename "$image" | cut -d '.' -f 1)"
  fi

  current_size=$(du -m "$1" | awk '{print $1}')
  Dry_Run "e2fsck -fa $1" $dry_run >/dev/null

  fixed_size=500
  new_size=$((current_size + fixed_size))
  Dry_Run "resize2fs $1 ${new_size}M  2>&1 | grep -v resize2fs >/dev/null" $dry_run

  mkdir -p "$2" >/dev/null
  Dry_Run sudo mount -o rw $1 $2 $dry_run
  UI "d"
}