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
  UI "Retrieving Target $image_name" "\n"
  INDENT=$INDENT_ALT
  if [ -f "$STOCK_DIR/$image_name/Target/$TARGET.img" ]; then
    imgsuffix=.img
  fi


  if [[ $copymount == "y" ]]; then
    Unmount $WORKING_DIR/$image_name/Target/$TARGET$imgsuffix
    rm -rf $WORKING_DIR/$image_name/Target/$TARGET$imgsuffix
    UI "Copying: $TARGET $image_name"
    mkdir -p $WORKING_DIR/$image_name/Target/
    sudo cp -a $STOCK_DIR/$image_name/Target/$TARGET$imgsuffix $WORKING_DIR/$image_name/Target/
    UI "d"
  fi

  if [[ $mount == "y" && $imgsuffix == ".img" ]]; then
    if [[ $copymount == "y" ]]; then
      mkdir -p $WORKING_DIR/$image_name/Target/$TARGET
      Mount $WORKING_DIR/$image_name/Target/$TARGET.img $WORKING_DIR/$image_name/Target/$TARGET
    fi
    Target_Mount=$WORKING_DIR/$image_name/Target/$TARGET
  elif [[ $imgsuffix != ".img" ]]; then
    Target_Mount=$WORKING_DIR/$image_name/Target/$TARGET
  fi
  Target_Path=$WORKING_DIR/$image_name/Target/$TARGET$imgsuffix
  INDENT=""
}

Unmount_Target()
{
  local image_name=$1

  Unmount $WORKING_DIR/$image_name/Target/$TARGET $WORKING_DIR/$image_name/Target/$TARGET.img
}

Checksum_Target()
{
  location=$1
  image_name=$2
  
  if [ -f "$STOCK_DIR/$image_name/Target/$TARGET.img" ]; then
    md5sum $STOCK_DIR/$image_name/Target/$TARGET.img >> $location
  else
    tar c  $STOCK_DIR/$image_name/Target/$TARGET | md5sum >> $location
  fi
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
    INDENT=""
    UI "Retrieving $model $image_name" "\n"
    INDENT=$INDENT_ALT

    if [ -f  "$STOCK_DIR/$image_name/Source/$model.img"  ]; then
      imgsuffix=.img
    fi
    if [[ $copymount == "y" ]]; then
      Unmount $WORKING_DIR/$image_name/Source/$model/$model$imgsuffix
      rm -rf $WORKING_DIR/$image_name/Source/$model/$model$imgsuffix
      UI "Copying: $model $image_name"
      mkdir -p $WORKING_DIR/$image_name/Source/$model/
      cp -a $STOCK_DIR/$image_name/Source/$model$imgsuffix $WORKING_DIR/$image_name/Source/$model/
      UI "d"
    fi

    if [[ $mount == "y" && $imgsuffix == ".img" ]]; then
      if [[ $copymount == "y" ]]; then
        mkdir -p $WORKING_DIR/$image_name/Source/$model
        Mount $WORKING_DIR/$image_name/Source/$model/$model.img $WORKING_DIR/$image_name/Source/$model/$model
      fi
      Source_Mount+=($WORKING_DIR/$image_name/Source/$model/$model)
    elif [[ $imgsuffix != ".img" ]]; then
      Source_Mount+=($WORKING_DIR/$image_name/Source/$model/$model)
    fi
    
    Source_Path+=($WORKING_DIR/$image_name/Source/$model/$model$imgsuffix)
    
  done
  INDENT=""
}

Unmount_Source()
{
  local image_name=$1
  for model in "${MODEL[@]}"; do
    Unmount $WORKING_DIR/$image_name/Source/$model/$model $WORKING_DIR/$image_name/Source/$model/$model.img
  done
}

Checksum_Source()
{
  location=$1
  image_name=$2
  
  for model in "${MODEL[@]}"; do
    if [ -f  "$STOCK_DIR/$image_name/Source/$model.img"  ]; then
      md5sum $STOCK_DIR/$image_name/Source/$model.img >> $location
    else 
      tar c  $STOCK_DIR/$image_name/Source/$model | md5sum >> $location
    fi
  done
}