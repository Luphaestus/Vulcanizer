Get_Target()
{
  local image_name=$1
  local mount=$2
  local reset=$3
  local copymount=$4
  local size=$5

  if [[ $reset = "y" ]]; then
    Target_Path=()
    Target_Mount=()
  fi


  UI "Retrieving: Target $image_name" "\n"
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
      Mount $WORKING_DIR/$image_name/Target/$TARGET.img $WORKING_DIR/$image_name/Target/$TARGET $size
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

Checksum_Target() {
  image_name=$1
  shift  
  locations=("$@")

  if [ -f "$STOCK_DIR/$image_name/Target/$TARGET.img" ]; then
    #checksum=$(md5sum "$STOCK_DIR/$image_name/Target/$TARGET.img")
    checksum=$(stat -c %Y "$STOCK_DIR/$image_name/Target/$TARGET.img")
  else
    #checksum=$(tar c "$STOCK_DIR/$image_name/Target/$TARGET" | md5sum)
    checksum=$(stat -c %Y "$STOCK_DIR/$image_name/Target/$TARGET")
  fi

  for location in "${locations[@]}"; do
    echo "$checksum" >> "$location"
  done
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
    UI "Retrieving: $model $image_name" "\n"
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
  image_name=$1
  shift  
  locations=("$@")
  
  for model in "${MODEL[@]}"; do
    if [ -f  "$STOCK_DIR/$image_name/Source/$model.img"  ]; then
      checksum=$(stat -c %Y "$STOCK_DIR/$image_name/Source/$model.img")
      #checksum=$(md5sum $STOCK_DIR/$image_name/Source/$model.img)
    else
      checksum=$(stat -c %Y "$STOCK_DIR/$image_name/Source/$model")
      #checksum=$(tar c  $STOCK_DIR/$image_name/Source/$model | md5sum)
    fi
    for location in "${locations[@]}"; do
      echo "$checksum" >> "$location"
    done
  done

}