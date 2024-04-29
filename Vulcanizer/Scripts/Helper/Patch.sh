SeSed() {
  dir="${!#}"
  commands="${@:1:$(($#-1))}"

  textlabel=$(ls -dZ "$dir")
  selabel=$(echo "$textlabel" | cut -d " " -f1)

  echo "Executing sed with: sed $commands" $dir
  sed $commands $dir

  chcon $selabel $dir
}

Commands_from_file()
{
  file_path=$1
  command=$2
  force=$3

  while IFS= read -r line; do
    success=false

    if [ -z "$line" ] || [[ $line == \#* ]]; then
      continue
    fi
    echo -ne ${OVERWRITE}"Processing line: $line"
    for dir in "${PATCH_DIRS[@]}"; do
      cd $dir >/dev/null
      full_command="${command//%s/$line}"


      if error_output=$(eval "$full_command" 2>&1);  then
        success=true
      fi
      cd - >/dev/null
    done
    if [ "$success" = false ]; then
      if [[ $force != "n" ]]; then
        echo -ne $OVERWRITE
        echo " "
        UI "!!$Command $full_command"
        echo $error_output
        return 1
      fi
    fi
  done < "$file_path"
  echo -ne $OVERWRITE
}