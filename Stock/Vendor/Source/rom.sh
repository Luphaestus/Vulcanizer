#!/bin/bash

  detect_images() {
      local image_files=($(ls -1 *.img 2>/dev/null))
      if [ ${#image_files[@]} -eq 0 ]; then
          echo "Error: No image files found in the current directory."
          exit 1
      fi
      echo "Detected image files:"
      for ((i=0; i<${#image_files[@]}; i++)); do
          echo "$(($i+1)). ${image_files[$i]}"
      done
      read -p "Enter the number of the image file: " image_number
      if [ "$image_number" -ge 1 ] && [ "$image_number" -le ${#image_files[@]} ]; then
          selected_image=${image_files[$(($image_number-1))]}
          echo "Selected image: $selected_image"
      else
          echo "Invalid selection. Please enter a valid number."
          exit 1
      fi
  }

Mount() {
    current_size=$(du -m "$selected_image" | awk '{print $1}')
    e2fsck -f "$selected_image"
    fixed_size=500
    new_size=$((current_size + fixed_size))
    resize2fs "$selected_image" "${new_size}M"
    mkdir "./mounted-${selected_image%.img}"
    sudo mount -o rw "$selected_image" "./mounted-${selected_image%.img}"
}

Unmount() {
    sudo umount "./mounted-${selected_image%.img}"
    rm -r "./mounted-${selected_image%.img}"
    e2fsck -f "$selected_image"
    resize2fs -M "$selected_image"
}

Resize() {
    read -p "Enter the new size for $selected_image in megabytes: " size
    if [[ "$size" =~ ^[0-9]+$ ]]; then
        current_size=$(du -m "$selected_image" | awk '{print $1}')
        new_size=$((current_size + size))
        resize2fs "$selected_image" "${new_size}M"
        echo "Resized $selected_image to $current_size megabytes."
    else
        echo "Invalid size. Please enter a valid number."
    fi
}

Zip() {
    read -p "Enter the new size for $selected_image in megabytes: " size
    if [[ "$size" =~ ^[0-9]+$ ]]; then
        current_size=$(du -m "$selected_image" | awk '{print $1}')
        new_size=$((current_size + size))
        resize2fs "$selected_image" "${new_size}M"
        echo "Resized $selected_image to $current_size megabytes."
    else
        echo "Invalid size. Please enter a valid number."
    fi
}

Flash() {
    Unmount
    adb reboot fastboot
    partition_name="${selected_image%.img}"
    fastboot flash "$partition_name" "$selected_image"
    paplay ./winsquare-6993.mp3

}


DoingFlags=false

GENERATE_LPMAKE_OPT()
{
    local OPT
    local GROUP_NAME="group_basic"
    local HAS_SYSTEM=false
    local HAS_VENDOR=false
    local HAS_PRODUCT=false
    local HAS_SYSTEM_EXT=false
    local HAS_ODM=false
    local HAS_VENDOR_DLKM=false
    local HAS_ODM_DLKM=false
    local HAS_SYSTEM_DLKM=false

    [[ "$TARGET_SINGLE_SYSTEM_IMAGE" == "qssi" ]] && GROUP_NAME="qti_dynamic_partitions"

    [ -f "system.img" ] && HAS_SYSTEM=true
    [ -f "vendor.img" ] && HAS_VENDOR=true
    [ -f "product.img" ] && HAS_PRODUCT=true
    [ -f "system_ext.img" ] && HAS_SYSTEM_EXT=true
    [ -f "odm.img" ] && HAS_ODM=true
    [ -f "vendor_dlkm.img" ] && HAS_VENDOR_DLKM=true
    [ -f "odm_dlkm.img" ] && HAS_ODM_DLKM=true
    [ -f "system_dlkm.img" ] && HAS_SYSTEM_DLKM=true

    OPT+=" -o super_empty.img"
    OPT+=" --device-size $TARGET_SUPER_PARTITION_SIZE"
    OPT+=" --metadata-size 65536 --metadata-slots 2"
    OPT+=" -g $GROUP_NAME:$TARGET_SUPER_GROUP_SIZE"

    if $HAS_SYSTEM; then
        OPT+=" -p system:readonly:0:$GROUP_NAME"
    fi
    if $HAS_VENDOR; then
        OPT+=" -p vendor:readonly:0:$GROUP_NAME"
    fi
    if $HAS_PRODUCT; then
        OPT+=" -p product:readonly:0:$GROUP_NAME"
    fi
    if $HAS_SYSTEM_EXT; then
        OPT+=" -p system_ext:readonly:0:$GROUP_NAME"
    fi
    if $HAS_ODM; then
        OPT+=" -p odm:readonly:0:$GROUP_NAME"
    fi
    if $HAS_VENDOR_DLKM; then
        OPT+=" -p vendor_dlkm:readonly:0:$GROUP_NAME"
    fi
    if $HAS_ODM_DLKM; then
        OPT+=" -p odm_dlkm:readonly:0:$GROUP_NAME"
    fi
    if $HAS_SYSTEM_DLKM; then
        OPT+=" -p system_dlkm:readonly:0:$GROUP_NAME"
    fi

    echo "$OPT"
}



while getopts ":cps:dz" opt; do
    case $opt in
        p)
            DoingFlags=true
            filename="${@: -1}"
            numeric_permissions=$(stat -c "%a" "$filename")
            echo "Numeric permissions for $filename: $numeric_permissions"
            ;;
        s)
            DoingFlags=true
            filename="${@: -1}"
            shift $((OPTIND - 1))
            permissions="$OPTARG"
            if [[ ! "$permissions" =~ ^[0-7]{3}$ ]]; then
                echo "Invalid permissions value: $permissions. It must be a three-digit octal number." >&2
                exit 1
            fi
            sudo chmod "$permissions" "$filename"
            echo "Changed permissions for $filename to $permissions."
            ;;
        d)


            DoingFlags=true
            sudo pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY dolphin "$(pwd)"
            ;;
        c)
            DoingFlags=true
            folder_name="oneUI6"
            rm -rf "$folder_name"
            cp -r ./zipTemplate "$folder_name"

            declare -a image_array=("vendor" "system" "product" "odm")
            declare -a addition_size=(100 100 20 20)
            for ((i=0; i<${#image_array[@]}; i++)); do
                img="${image_array[$i]}"
                selected_image="$img.img"
                size="${addition_size[$i]}"
                Unmount
                current_size=$(du -m "$selected_image" | awk '{print $1}')
                new_size=$((current_size + size))
                resize2fs "$selected_image" "${new_size}M"
                echo "Resized $selected_image from $current_size to $new_size megabytes. Increase of $size megabytes."

                img2simg "./$img.img" "./$folder_name/$img.sparse"
                echo 4 | img2sdat -o "./$folder_name/images" -p "$img" "./$folder_name/$img.sparse"
                size=$(( $(wc -c < "./$img.img") + 60240))
                rm "./$folder_name/$img.sparse"
                brotli -q 5 "./$folder_name/images/$img.new.dat" -o "./$folder_name/images/$img.new.dat.br"
                rm "./$folder_name/images/$img.new.dat"
                echo "resize $img $size" >> "./$folder_name/shared/op_list"
            done

            cd "$folder_name" && zip -0r "../$folder_name.zip" ./* && cd -
            paplay ./winsquare-6993.mp3

            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done


if [ "$DoingFlags" = true ]; then
  exit 0
fi

detect_images


echo "Select an option:"
echo "1. Mount"
echo "2. Unmount"
echo "3. Resize"
echo "4. Flash"


read -p "Enter your choice (1, 2, 3, or 4): " choice

case $choice in
    1) Mount ;;
    2) Unmount ;;
    3) Resize ;;
    4) Flash ;;
    *) echo "Invalid choice. Please enter 1, 2, or 3." ;;
esac
