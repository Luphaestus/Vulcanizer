process_file() {
    local file="$1"
    echo -ne "$OVERWRITE$file"
    local text=$(ls -dZ "$file")
    local selabel=$(echo "$text" | cut -d " " -f1)

    if [ "$file" = "." ]; then
        sudo echo "/$mountpoint $selabel" >> "$contexts"
        sudo stat -c "/ %u %g %a" "$file" >> "$config"
    else
      if [[ $mountpoint == "/" ]]; then
        local contextmount=""
      else
        contextmount="/"
      fi
      sudo echo "$contextmount$mountpoint$file $selabel" >> "$contexts"
      sudo stat -c "$mountpoint%n %u %g %a" "$file" >> "$config"
    fi
    unset file text selabel permissions user_id group_id
}

Convert2Erofs() {
  local img_path=$1
  mountpoint=$2

  local img_mount="${img_path%.img}"
  local img_name=$(basename "$img_mount")
  if ! mountpoint -q "$img_mount"; then
    Mount "$img_path" "$img_mount"
  fi
  cd $img_mount

  TMP="../EroFS"
  mkdir -p $TMP
  config="$TMP/${img_name}_config.txt"
  contexts="$TMP/${img_name}_contexts.txt"

  UI "h|Converting: $img_name to EROFS" "\n"

  touch  "$config"
  > "$config"
  touch  "$contexts"
  > $contexts

  process_file "."
  UI "Compiling permissions"
  sudo  find * | while read file;do process_file "$file"; done
  echo -e $OVERWRITE$SUCCESS_FG"Successfully compiled permissions!$RESET"

  sed -i "s/\x0//g" "$contexts" \
    && sed -i 's/\./\\./g' "$contexts" \
    && sed -i 's/\+/\\+/g' "$contexts" \
    && sed -i 's/\[/\\[/g' "$contexts"


  sudo $EXTERNAL_DIR/mkfs/mkfs.erofs -b 4096 -T 1230735600 --fs-config-file $config --file-contexts $contexts --mount-point=$mountpoint "../$img_name.erofs" "."
  cd - >/dev/null
}