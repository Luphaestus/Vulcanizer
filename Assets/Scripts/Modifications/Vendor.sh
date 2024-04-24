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

Build_Exynos_Vendor()
{
  ####### Testing vars #######
  local copymount_vendor="n"

  if [[ $CREATE_VENDOR != "y" ]]; then
    return 0
  fi


  UI "t|Building Vendor"

  Get_Target "Vendor" "y" "Y" $copymount_vendor
  Get_Source "Vendor" "y" "y" $copymount_vendor

  PATCH_DIRS=("${Source_Mount[@]}")
  PATCH_MODEL=()
  for dir in "${Patch_Dirs[@]}"; do
    PATCH_MODEL+=($(basename "$dir"))
  done

  if [[ $PATCH_VENDOR == "y" ]]; then
    UI "t|Patching Vendor(s)"

    #Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_DELETE "rm -r %s"
    Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_COPY "sudo rm -r %s" "n"

    Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_COPY "sudo cp -a $Target_Mount/%s %s"
    Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_MISC "%s"
  fi

  if [[ $COMMON_VENDOR == "y" ]]; then
    UI "t|Creating Common Vendors"
    MOUNTED_COMMON_IMAGES=("${Source_Mount[@]}")
    Common_Image "$WORKING_DIR/Vendor/Shared/CommomVendor" ${Source_Path[0]}
    if [[ $EROFS == "y" ]]; then
      Convert2Erofs $commonmount.img /
    fi
    Unmount $commonmount $commonmount.img
  fi

 # Unmount_Target "Vendor"
#  Unmount_Source "Vendor"

}

COMMON_COMMANDS+=("Build_Exynos_Vendor")