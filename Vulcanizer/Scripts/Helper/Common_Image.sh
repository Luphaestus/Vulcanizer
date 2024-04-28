MOUNTED_COMMON_IMAGES=()

Common_Image()
{
  commonmount=$1
  imgpath=$2
  imgname=$3
  erofsSymlinks=()
  if [[ "$imgpath" =~ \.img$ ]]; then
    rm -rf $commonmount.img
    Unmount $commonmount
    mkdir -p $commonmount
    Unmount "${MOUNTED_COMMON_IMAGES[0]}"
    sudo cp -a $imgpath $commonmount.img
    Mount $imgpath "${MOUNTED_COMMON_IMAGES[0]}"
    Mount $commonmount.img $commonmount
  else
    rm -rf $commonmount
    mkdir -p $commonmount
    cp -a $imgpath/* $commonmount
  fi

  for ((index = 1; index < ${#MOUNTED_COMMON_IMAGES[@]}; index++)); do
      mountedimg="${MOUNTED_COMMON_IMAGES[$index]}"
      UI "diff: $mountedimg $commonmount"
      echo " "
      INDENT=$INDENT_ALT
      diff_output=$(sudo diff -rq "$mountedimg" "$commonmount" 2>/dev/null | grep differ | awk '{print $2}')
      if [[ ! -z "${diff_output// }" ]]; then
        while IFS= read -r line; do
          trimmed_string="${line#${MOUNTED_COMMON_IMAGES[$index]}/}"
          echo -ne $OVERWRITE$INDENT$trimmed_string
          for ((i=$index; i>=0; i--)) do
            img_mounted=${MOUNTED_COMMON_IMAGES[$i]}
            mkdir -p "$(dirname "$img_mounted-specific/$trimmed_string")"
            sudo cp -a "$img_mounted/$trimmed_string" "$img_mounted-specific/$trimmed_string"
          done

          rm "$commonmount/$trimmed_string"
          if [[ $EROFS == "y" ]]; then
            erofsSymlinks+=("/odm/$imgname/$trimmed_string $commonmount/$trimmed_string")
          fi

        done <<< "$diff_output"
      else
          UI "!No differing files found."
      fi
      echo -e $OVERWRITE$SUCCESS_FG$INDENT"Successfully resolved differing files$RESET"
      diff_output=$(diff -rq "$mountedimg" "$commonmount" 2>/dev/null | grep "Only in"  | awk '{gsub(/:/,"/",$3); gsub(/:/,"/",$4); print $3, $4}'| tr -d ' ')
      if [[ ! -z "${diff_output// }" ]]; then
        while IFS= read -r line; do
          if echo "$line" | grep -q "$commonmount"; then
            trimmed_string="${line#$commonmount/}"
            echo -ne "$OVERWRITE$INDENT Only in $trimmed_string"
            for ((i=$index; i>=0; i--))  do
              img_mounted=${MOUNTED_COMMON_IMAGES[$i]}
              if [ -e "$img_mounted/$trimmed_string" ] && [ ! -e "$img_mounted-specific/$trimmed_string" ]; then
                  mkdir -p "$(dirname "$img_mounted-specific/$trimmed_string")"
                  cp -a "$img_mounted/$trimmed_string"  "$img_mounted-specific/$trimmed_string"
              fi
            done
              rm -rf "$commonmount/$trimmed_string"
              if [[ $EROFS == "y" ]]; then
                erofsSymlinks+=("/odm/$imgname/$trimmed_string $commonmount/$trimmed_string")
              fi
          else
            img_mounted=${MOUNTED_COMMON_IMAGES[$index]}

            trimmed_string="${line#${MOUNTED_COMMON_IMAGES[$index]}/}"
            echo -ne "$OVERWRITE$INDENT Only in $line"
            mkdir -p  "$(dirname "$img_mounted-specific/$trimmed_string")"
            cp -a "$img_mounted/$trimmed_string" "$img_mounted-specific/$trimmed_string"
            if [[ $EROFS == "y" ]]; then
              erofsSymlinks+=("/odm/$imgname/$trimmed_string $commonmount/$trimmed_string")
            fi
          fi
          done <<< "$diff_output"
      else
          UI "!No unique files found."
      fi
    echo -e $OVERWRITE$SUCCESS_FG$INDENT"Successfully resolved unique files$RESET"
    INDENT=""
  done
  
  
  if [[ $EROFS == "y" ]]; then
    echo " "
    UI "h|Creating Symlinks"
    for symlink in "${erofsSymlinks[@]}"; do
      src=$(echo "$symlink" | awk '{print $1}')  
      dest=$(echo "$symlink" | awk '{print $2}') 
    
      if [ ! -L "$dest" ]; then
        ln -s "$src" "$dest"
      fi 
    done
    echo -e $OVERWRITE$SUCCESS_FG"Successfully made Symlinks$RESET"
  fi  
  echo " "
}