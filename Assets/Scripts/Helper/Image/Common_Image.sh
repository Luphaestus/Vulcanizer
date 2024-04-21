MOUNTED_COMMON_IMAGES=()

Common_Image()
{
  commonmount=$1
  imgpath=$2
  imgname=$3
  echo $commonmount
  mkdir -p $commonmount#
  echo $imgpath
  umount $imgpath
  sudo cp -a $imgpath $commonmount.img
  Mount $imgpath "${MOUNTED_COMMON_IMAGES[0]}"
  Mount $commonmount.img $commonmount
  for ((index = 1; index < ${#MOUNTED_COMMON_IMAGES[@]}; index++)); do
      mountedimg="${MOUNTED_COMMON_IMAGES[$index]}"
      echo " diff $mountedimg $commonmount"

      diff_output=$(sudo diff -rq "$mountedimg" "$commonmount" | grep differ | awk '{print $2}')
      if [[ ! -z "${diff_output// }" ]]; then
          while IFS= read -r line; do
            trimmed_string="${line#${MOUNTED_COMMON_IMAGES[$index]}/}"
            echo $trimmed_string
            for ((i=$index; i>=0; i--))
            do
              img_mounted=${MOUNTED_COMMON_IMAGES[$i]}
              mkdir -p "$(dirname "$img_mounted-specific/$trimmed_string")"
              sudo cp -a "$img_mounted/$trimmed_string" "$img_mounted-specific/$trimmed_string"
              if [[ $EROFS == "y" ]]; then
                ln -s /odm/$imgname/$trimmed_string
              fi
            done

          rm "$commonmount/$trimmed_string"

          done <<< "$diff_output"
      else
          echo "No differ found in the files."
      fi
      echo
      diff_output=$(diff -rq "$mountedimg" "$commonmount" 2>/dev/null | grep "Only in"  | awk '{gsub(/:/,"/",$3); gsub(/:/,"/",$4); print $3, $4}'| tr -d ' ')
      if [[ ! -z "${diff_output// }" ]]; then
        while IFS= read -r line; do
          echo "$line"
          if echo "$line" | grep -q "$commonmount"; then

            trimmed_string="${line#${MOUNTED_COMMON_IMAGES[$index]}/}"
            echo "Only pin $trimmed_string"
            for ((i=$index; i>=0; i--))  do
              img_mounted=${MOUNTED_COMMON_IMAGES[$i]}
              if [ -e "$img_mounted/$trimmed_string" ] && [ ! -e "$img_mounted-specific/$trimmed_string" ]; then
                  mkdir -p "$(dirname "$img_mounted-specific/$trimmed_string")"
                  cp -a "$img_mounted/$trimmed_string"  "$img_mounted-specific/$trimmed_string"
                  if [[ $EROFS == "y" ]]; then
                    ln -s /odm/$imgname/$trimmed_string
                  fi
              fi
            done
              rm -rf "$commonmount/$trimmed_string"
          else
            img_mounted=${MOUNTED_COMMON_IMAGES[$index]}

            trimmed_string="${line#${MOUNTED_COMMON_IMAGES[$index]}/}"
            echo "Only in $line"
            mkdir -p  "$(dirname "$img_mounted-specific/$trimmed_string")"
            cp -a "$img_mounted/$trimmed_string" "$img_mounted-specific/$trimmed_string"
            if [[ $EROFS == "y" ]]; then
              ln -s /odm/$imgname/$trimmed_string
            fi
          fi
          done <<< "$diff_output"
      else
          echo "No only in found in the files."
      fi
#

  done
}