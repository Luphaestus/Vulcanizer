Get_Target()
{
  local image_name=$1
  local mount=$2
  local reset=$3
  local copymount=$4

  if [[ $reset = "y" ]]; then
    Target_Path=()
    Target_Mount=()
  fi
  UI "----" "\n"
  if [[ $copymount == "y" ]]; then
    rm -rf $WORKING_DIR/$image_name/Target/$TARGET.img
    UI "Copying: $TARGET $image_name"
    mkdir -p $WORKING_DIR/$image_name/Target/
    sudo cp -a $STOCK_DIR/$image_name/Target/$TARGET.img $WORKING_DIR/$image_name/Target/
    UI "d"
  fi
  if [[ $mount == "y" ]]; then
    if [[ $copymount == "y" ]]; then
      mkdir -p $WORKING_DIR/$image_name/Target/$TARGET
      Mount $WORKING_DIR/$image_name/Target/$TARGET.img $WORKING_DIR/$image_name/Target/$TARGET
    fi
    Target_Mount=$WORKING_DIR/$image_name/Target/$TARGET
  fi
  Target_Path=$WORKING_DIR/$image_name/Target/$TARGET.img
}

Unmount_Target()
{
  local image_name=$1

  Unmount $WORKING_DIR/$image_name/Target/$TARGET.img $WORKING_DIR/$image_name/Target/$TARGET
}


Get_Source()
{
  local image_name=$1
  local mount=$2
  local reset=$3
  local copymount=$4

  if [[ $reset != "n" ]]; then
    Source_Path=()
    Source_Mount=()
  fi

  for model in "${MODEL[@]}"; do
    UI "----" "\n"
    if [[ $copymount == "y" ]]; then
      rm -rf $WORKING_DIR/$image_name/Source/$model/$model.img
      UI "Copying: $model $image_name"
      mkdir -p $WORKING_DIR/$image_name/Source/$model/
      cp -a $STOCK_DIR/$image_name/Source/$model.img $WORKING_DIR/$image_name/Source/$model/
      UI "d"
    fi

    if [[ $mount == "y" ]]; then
      if [[ $copymount == "y" ]]; then
        mkdir -p $WORKING_DIR/$image_name/Source/$model
        Mount $WORKING_DIR/$image_name/Source/$model/$model.img $WORKING_DIR/$image_name/Source/$model/$model
      fi
      Source_Mount+=($WORKING_DIR/$image_name/Source/$model/$model)
    fi
    Source_Path+=($WORKING_DIR/$image_name/Source/$model/$model.img)
  done
}

Unmount_Source()
{
  local image_name=$1
  for model in "${MODEL[@]}"; do
    Unmount $WORKING_DIR/$image_name/Source/$model/$model.img $WORKING_DIR/$image_name/Source/$model/$model
  done
}