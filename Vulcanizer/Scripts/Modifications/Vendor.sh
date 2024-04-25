#MOVE WHEN DOING SYSTEM PATCHES
deleteTag()
{
    tagname=$1
    start=$(grep -n "$tagname" "$manifestxml" | awk -F: '{print $1-1}')
    first=$(sed -n "${start},\$p" "$manifestxml" | grep -n "</hal>" | head -n 1 | awk -F: '{print $1}')
    firsttotal=$((start + first-1))
    sed -i "${start},${firsttotal}d" "$manifestxml"
    echo "manifest.xml : $start - $firsttotal"
}

Vendor_Cheksum()
{
  location=$1
  UI "Making Vendor Checksums"
  > "$location"
  chown "${SUDO_USER:-$(whoami)}" "$location"
  Checksum_Target $location Vendor 2>/dev/null
  Checksum_Source $location Vendor  2>/dev/null
  md5sum $RESOURCES_DIR/Vendor/* >> $location
  echo "Patch Vendor: "$PATCH_VENDOR >> $location
  echo "Common Image: "$COMMON_VENDOR >> $location
  UI "d"
}


Build_Exynos_Vendor()
{
  ####### Testing vars #######
  local copymount_vendor="y"

  if [[ $CREATE_VENDOR != "y" ]]; then
    return 0
  fi


  UI "t|Building Vendor"
  
  local TestCheksum=$STOCK_DIR/Vendor/TestCheksum.txt
  local SaveChecksum=$STOCK_DIR/Vendor/Cheksum.txt
  Vendor_Cheksum $TestCheksum
  
  old_checksum=""
  if [ -f "$SaveChecksum" ]; then
      old_checksum=$(md5sum "$SaveChecksum" | awk '{print $1}')
  fi
  
  new_checksum=""
  if [ -f "$TestCheksum" ]; then
      new_checksum=$(md5sum "$TestCheksum" | awk '{print $1}')
  fi

  if ! [[ "$FORCE_VENDOR" == "y" || \
        (-f "$SaveChecksum" && \
         "$old_checksum" == "$new_checksum") ]]; then
    mv "$TestCheksum" "$SaveChecksum"

    UI "h|Retrieving Stock Vendors"
    Get_Target "Vendor" "y" "Y" $copymount_vendor
    Get_Source "Vendor" "y" "y" $copymount_vendor
  
    PATCH_DIRS=("${Source_Mount[@]}")
    PATCH_MODEL=()  
    for dir in "${Patch_Dirs[@]}"; do
      PATCH_MODEL+=($(basename "$dir"))
    done
  
    if [[ $PATCH_VENDOR == "y" ]]; then
      echo " "
      UI "h|Patching Vendor(s)"
      UI Running Delete Patches
      echo " "
      Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_DELETE "rm -r %s"
      UI Running Copy Patches
      echo " "
      Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_COPY "sudo rm -r %s" "n"
      Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_COPY "sudo cp -a $Target_Mount/%s %s"
      UI Running Misc Pathes
      echo " "
      Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_MISC "%s"
    fi
  
    if [[ $COMMON_VENDOR == "y" ]]; then
      echo " "
      UI "h|Creating Common Vendors"
      MOUNTED_COMMON_IMAGES=("${Source_Mount[@]}")
      Common_Image "$WORKING_DIR/Vendor/Shared/CommomVendor" ${Source_Path[0]}
      if [[ $EROFS == "y" ]]; then
        Convert2Erofs $commonmount.img /
      fi
      Unmount $commonmount $commonmount.img
    fi
    echo " "
    UI "h|Cleaning Up"
    Unmount_Target "Vendor"
    Unmount_Source "Vendor"
  else
    echo "files identical "
  fi

}

  COMMON_COMMANDS+=("Build_Exynos_Vendor")