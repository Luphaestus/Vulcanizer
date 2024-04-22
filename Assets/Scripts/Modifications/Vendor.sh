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
  if [[ $CREATE_VENDOR != "y" ]]; then
    return 0
  fi

  UI "t|Building Vendor"
  Get_Target "Vendor" "y" "Y" "n"
  Get_Source "Vendor" "y" "y" "n"

  PATCH_DIRS=("${Source_Mount[@]}")
  PATCH_MODEL=()
  for dir in "${Patch_Dirs[@]}"; do
    PATCH_MODEL+=($(basename "$dir"))
  done

  Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_DELETE "rm -r %s"
  Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_COPY "sudo rm -r %s" "n"

  Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_COPY "sudo cp -a $Target_Mount/%s %s"
  Commands_from_file $RESOURCES_DIR/Vendor/$VENDOR_MISC "%s"

  if [[ $COMMON ]]; then
    UI "t|Patching Vendor(s)"
    MOUNTED_COMMON_IMAGES=("${Source_Mount[@]}")
    Common_Image "$WORKING_DIR/Vendor/Shared/CommomVendor" ${Source_Path[0]}
  fi

}

COMMON_COMMANDS+=("Build_Exynos_Vendor")