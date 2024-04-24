process_file() {
    local file="$1"
    echo $file
    local text=$(ls -dZ "$file")
    local selabel=$(echo "$text" | cut -d " " -f1)

    if [ "$file" = "." ]; then

      if [ "$img" = "system" ]; then
          sudo echo "/ $selabel" >> "$contexts"
      else
          sudo echo "/$img $selabel" >> "$contexts"
      fi
      sudo stat -c "/ %u %g %a" "$file" >> "$config"
    else
      if [ "$img" = "system" ]; then
          sudo echo "/$file $selabel" >> "$contexts"
          sudo stat -c "%n %u %g %a" "$file" >> "$config"
      else
          sudo echo "/$img/$file $selabel" >> "$contexts"
          sudo stat -c "$img/%n %u %g %a" "$file" >> "$config"
      fi
    fi
    unset file text selabel permissions user_id group_id
}

img="system"
TMP="../TMP"
mkdir -p $TMP
config="$TMP/${img}_config.txt"
contexts="$TMP/${img}_contexts.txt"

echo "Creating $img filesystem, $config, and $contexts"

touch  "$config"
> "$config"
touch  "$contexts"
> $contexts

process_file "."
sudo  find * | while read file;do process_file "$file"; done

sed -i "s/\x0//g" "$contexts" \
  && sed -i 's/\./\\./g' "$contexts" \
  && sed -i 's/\+/\\+/g' "$contexts" \
  && sed -i 's/\[/\\[/g' "$contexts"


MY_DIR=$(pwd);
if [ "$img" = "system" ]; then
  mountpoint="/"
else
  mountpoint="/$img"
fi

sudo ../mkfs.erofs -z lz4hc,9 -b 4096 -T 1230735600 --fs-config-file $config --file-contexts $contexts --mount-point=$mountpoint "$TMP/$img.erofs" "."


