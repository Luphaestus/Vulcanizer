Build_Odm()
{
  if [[ $CREATE_ODM != "y" ]]; then
    return 0
  fi
  UI "t|Building ODM"
  UI "h|Preparing Odm Image"
  Unmount_All "$WORKING_DIR/Odm/"
  for item in "$WORKING_DIR/Odm/"*; do
    if [[ $item != $SPECIFIC_FILES ]]; then
      rm -r $item
    fi
  done

  if [[ $COMMON == "Y" ]]; then

    for item in "$SPECIFIC_FILES/"*; do
      for item in "$WORKING_DIR/Odm/"*; do
        if [[ $item != $SPECIFIC_FILES ]]; then
          rm -r $item
        fi
      done
      Get_Target "Odm" "y" "y" "y" 3000
      echo " "
      UI "h|Copying specific files"
      cp -aL $item/* "$Target_Mount"
      echo -e $SUCCESS_FG"Successfully copied specific files$RESET"
      echo " "
      UI "h|Cleaning Up"
      Convert2img $Target_Mount odm/
      Unmount_Target "Odm"
      mkdir -p $OUT_DIR/Odm/
      if [[ $COMPRESS == "y" ]]; then
        Compress_Image "${Target_Mount%/*}"/out/$(basename "$Target_Mount").img
        cp -a  "${Target_Mount%/*}"/out/compressed/* $OUT_DIR/$(basename "$item")/Odm/
      else
        cp -a  "${Target_Mount%/*}"/out/$(basename "$Target_Mount").img $OUT_DIR/$(basename "$item")/Odm/Odm.img
      fi
    done
  else
    Get_Target "Odm" "y" "y" "y"
    Convert2img $Target_Mount odm/

    Unmount_Target "Odm"
    if [[ "$COMPRESS" == "y" ]]; then
      Compress_Image  "${Target_Mount%/*}"/out/$(basename "$Target_Mount").img
    fi
    Get_Source "Odm" "y" "y" "n"

    if [[ $COMPRESS == "y" ]]; then
      copypath="${Target_Mount%/*}"/out/compressed/*
    else
      copypath="${Target_Mount%/*}"/out/$(basename "$Target_Mount").img
      name=Odm.img
    fi

    for mount in "${Source_Mount[@]}"; do
      UI "Copying: $(basename "$mount")"

      mkdir -p $OUT_DIR/$(basename "$mount")/Odm/$name
      cp -aL $copypath $OUT_DIR/$(basename "$mount")/Odm/
      UI "d"
    done

  fi
}

LATE_COMMON_COMMANDS+=("Build_Odm")