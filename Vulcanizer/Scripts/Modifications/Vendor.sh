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
  images=$1
  UI "Making Vendor Checksums"
  > "$images"
  chown "${SUDO_USER:-$(whoami)}" "$images"
  
  Checksum_Target Vendor $images 2>/dev/null
  Checksum_Source Vendor $images 2>/dev/null
  md5sum "$(realpath "$BASH_SOURCE")" >> $images
  echo "Patch Vendor: "$PATCH_VENDOR >> $images
  echo "Common Image: "$COMMON_VENDOR >> $images
  md5sum $RESOURCES_DIR/Vendor/* >> $images
  
  

  UI "d"
}


Build_Exynos_Vendor()
{

  if [[ $CREATE_VENDOR != "y" ]]; then
    return 0
  fi
  UI "t|Building Vendor"

  if [[ $SKIPVENDORCHECKSUM != "y" ]]; then
    if [[ $FORCE_VENDOR != "y" ]]; then
      local TestImagesChecksum=$STOCK_DIR/Vendor/TestCheksumImages.txt
      local SaveChecksumImages=$STOCK_DIR/Vendor/CheksumImages.txt
      Vendor_Cheksum $TestImagesChecksum $TestVendorConfig
    fi
    if [[ "$FORCE_VENDOR" == "y" ]] || ! Compare_Cheksum "$TestImagesChecksum" "$SaveChecksumImages"; then
      echo " "
      UI "h|Retrieving Stock Vendors"

      ##test var##

      if [[ $COPYVENDOR == "y" ]]; then
        Unmount_All "$WORKING_DIR/Vendor/"
        rm -rf "$WORKING_DIR/Vendor/"
        mkdir -p "$WORKING_DIR/Vendor/"

        Get_Target "Vendor" "y" "Y" $COPYVENDOR
        Get_Source "Vendor" "y" "y" $COPYVENDOR
      fi
    
      PATCH_DIRS=("${Source_Mount[@]}")
      PATCH_MODEL=()  
      for dir in "${Patch_Dirs[@]}"; do
        PATCH_MODEL+=($(basename "$dir"))
      done
      echo " "
      if [[ $PATCH_VENDOR == "y" ]]; then
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
        echo " "
      fi

      if [[ $COMMON_VENDOR == "y" ]]; then
        UI "h|Creating Common Vendors"
        MOUNTED_COMMON_IMAGES=("${Source_Mount[@]}")
        Common_Image "$WORKING_DIR/Vendor/Shared/CommomVendor" ${Source_Path[0]} Vendor
        Convert2img $commonmount vendor/
      else
        for mount in "${Source_Mount[@]}"; do
          Convert2img $mount vendor/
        done
      fi

      UI "h|Cleaning Up"
      Unmount_Target "Vendor"
      Unmount_Source "Vendor"

      if [[ $COMPRESS == "y" ]]; then
        if [[ $COMMON_VENDOR == "y" ]]; then
            Compress_Image "${commonmount%/*}"/out/$(basename "$commonmount").img
        else
          for mount in "${Source_Mount[@]}"; do
            Compress_Image  "${mount%/*}"/out/$(basename "$mount").img
          done
        fi
      fi

      if [[ $FORCE_VENDOR != "y" ]]; then
        mv "$TestImagesChecksum" "$SaveChecksumImages"
      fi

    else
      UI "Vendor already compiled"
    fi
  fi
  echo " "
  UI "h|Moving build to output folder"
  Get_Target "Vendor" "y" "Y" "n"
  Get_Source "Vendor" "y" "y" "n"



  if [[ $COMMON_VENDOR != "y" ]]; then
    for mount in "${Source_Mount[@]}"; do
      UI "Copying: $(basename "$mount")"
      if [[ $COMPRESS == "y" ]]; then
        copypath="${mount%/*}"/out/compressed/*
      else
        copypath="${mount%/*}"/out/$(basename "$mount").img
      fi
      mkdir -p $OUT_DIR/$(basename "$mount")/Vendor/
      cp -aL $copypath $OUT_DIR/$(basename "$mount")/Vendor/
      UI "d"
    done
  else
    if [[ $COMPRESS == "y" ]]; then
      copypath=$WORKING_DIR/Vendor/Shared/out/compressed/*
    else
      copypath=$WORKING_DIR/Vendor/Shared/out/CommomVendor.img
    fi
    mkdir -p $OUT_DIR/Vendor/

    cp -a $copypath $OUT_DIR/Vendor/
  fi
}

COMMON_COMMANDS+=("Build_Exynos_Vendor")