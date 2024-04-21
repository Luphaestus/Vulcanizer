Get_Target()
{
  local image_name=$1
  local mount=$2
  local reset=$3
  local dry_run=$4
  if [[ $reset = "y" ]]; then
    Target_Path=()
    Target_Mount=()
  fi
  UI "----" "\n"
  Dry_Run rm -rf $WORKING_DIR/$image_name/Target/$TARGET.img $dry_run
  UI "Copying: $TARGET $image_name"
  Dry_Run mkdir -p $WORKING_DIR/$image_name/Target/ $dry_run
  Dry_Run cp -a $STOCK_DIR/$image_name/Target/$TARGET.img $WORKING_DIR/$image_name/Target/ $dry_run
  UI "d"

  if [[ $mount == "y" ]]; then
    Dry_Run mkdir -p $WORKING_DIR/$image_name/Target/$TARGET $dry_run
    Mount $WORKING_DIR/$image_name/Target/$TARGET.img $WORKING_DIR/$image_name/Target/$TARGET $dry_run
    Target_Mount=$WORKING_DIR/$image_name/Target/$TARGET
  fi
  Target_Path=$WORKING_DIR/$image_name/Target/$TARGET.img

}

Get_Source()
{
  local image_name=$1
  local mount=$2
  local reset=$3
  local dry_run=$4

  if [[ $reset != "n" ]]; then
    Source_Path=()
    Source_Mount=()
  fi

  for model in "${MODEL[@]}"; do
    UI "----" "\n"
    Dry_Run rm -rf $WORKING_DIR/$image_name/Source/$model/$model.img $dry_run
    UI "Copying: $model $image_name"
    Dry_Run mkdir -p $WORKING_DIR/$image_name/Source/$model/ $dry_run
    Dry_Run cp -a $STOCK_DIR/$image_name/Source/$model.img $WORKING_DIR/$image_name/Source/$model/ $dry_run
    UI "d"

    if [[ $mount == "y" ]]; then
      Dry_Run mkdir -p $WORKING_DIR/$image_name/Source/$model $dry_run
      Mount $WORKING_DIR/$image_name/Source/$model/$model.img $WORKING_DIR/$image_name/Source/$model/$model $dry_run
      Source_Mount+=($WORKING_DIR/$image_name/Source/$model/$model)
    fi
    Source_Path+=($WORKING_DIR/$image_name/Source/$model/$model.img)
  done
}