Build_Product()
{
  if [[ $CREATE_PRODUCT != "y" ]]; then
    return 0
  fi
  UI "t|Building Vendor"
  UI "h|Retrieving Product"
  Unmount_All "$WORKING_DIR/Product/"
  rm -rf  $WORKING_DIR/Product/*

  Get_Target "Product" "y" "y" "y"
  Get_Source "Product" "y" "y" "y"
  rm -rf $WORKING_DIR/Product/framework_apk
  rm -rf $WORKING_DIR/Product/apkout
  echo " "
  UI "h|Patching Product"
  PATCH_DIRS=($Target_Mount)
  UI Running Delete Patches
  echo " "
  #Commands_from_file $RESOURCES_DIR/Product/$PRODUCT_DELETE "rm -r %s"
  UI Running Misc Patches
  echo " "
  Commands_from_file $RESOURCES_DIR/Product/$PRODUCT_MISC "%s"
  echo " "
  UI "h|Patching Apks"
  for mount in "${Source_Mount[@]}"; do
    UI "Decompiling $(basename $mount) rro"
    mkdir -p $WORKING_DIR/Product/framework_apk/"$(basename $mount)"/
    cp -a $mount/overlay/framework-res__auto_generated_rro_product.apk $WORKING_DIR/Product/framework_apk/$(basename $mount)/
    Decompile_Apk $WORKING_DIR/Product/framework_apk/"$(basename $mount)"/framework-res__auto_generated_rro_product.apk >/dev/null
    UI "d"
    cp -a $WORKING_DIR/Product/framework_apk/"$(basename $mount)"/framework-res__auto_generated_rro_product/res/values/* $WORKING_DIR/Product/framework_apk/target/framework-res__auto_generated_rro_product/res/values/
    UI "Compiling "$(basename $mount)" rro"
    Compile_Apk $WORKING_DIR/Product/framework_apk/target/framework-res__auto_generated_rro_product $WORKING_DIR/Product/apkout/$(basename $mount)/ >/dev/null
    UI "d"
    echo " "
  done
  if [[ $COMMON == "y" ]]; then
    UI "h|Creating Common Product"
    UI "Copying: Specific Files"
    for mount in "${Source_Mount[@]}"; do
      rm -rf  $SPECIFIC_FILES/"$(basename $mount)"/Product/
      mkdir -p $WORKING_DIR/Product/Pathced_Dir/"$(basename $mount)/"product/overlay/

      cp -a $WORKING_DIR/Product/apkout/"$(basename $mount)"/framework-res__auto_generated_rro_product.apk  $WORKING_DIR/Product/Pathced_Dir/"$(basename $mount)"/product/overlay/
    done
    UI "d"

    Convert2img $Target_Mount product/
    Unmount_Target "Product"
    Unmount_Source "Product"

    if [[ $COMPRESS == "y" ]]; then
        Compress_Image "${Target_Mount%/*}"/out/"$(basename "$Target_Mount")".img
    fi
  else
    for mount in "${Source_Mount[@]}"; do
      rm -rf "${Target_Mount%/*}"/out/*
      UI "h|Creating $(basename $mount) Product"
      mkdir -p $WORKING_DIR/Product/Pathced_Dir/"$(basename $mount)/"
      Get_Target "Product" "y" "y" "n"
      cp -a $WORKING_DIR/Product/apkout/"$(basename $mount)"/framework-res__auto_generated_rro_product.apk $Target_Mount/overlay/
      Convert2img $Target_Mount product/
      Unmount_Source "Product"
      if [[ $COMPRESS == "y" ]]; then
        Compress_Image "${Target_Mount%/*}"/out/"$(basename "$Target_Mount")".img
        cp -a "${Target_Mount%/*}"/out/compressed/* $WORKING_DIR/Product/Pathced_Dir/"$(basename $mount)/"
      else
        cp -a "${Target_Mount%/*}"/out/"$(basename "$Target_Mount")".img $WORKING_DIR/Product/Pathced_Dir/"$(basename $mount)/"
      fi
    done
  fi

 }

COMMON_COMMANDS+=("Build_Product")