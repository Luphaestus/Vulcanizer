SeSed()
{
  commands="$*"
  dir="${!#}"
  textlabel=$(ls -dZ "$dir")
  selabel=$(echo "$textlabel" | cut -d " " -f1)
  echo $commands
  sed $commands
  chcon $selabel $dir
}

Commands_from_file()
{
  file_path=$1
  command=$2
  force=$3

  while IFS= read -r line; do
    success=false
    echo "Processing line: $line"
    for dir in "${PATCH_DIRS[@]}"; do
      cd $dir >/dev/null
      full_command="${command//%s/$line}"
      echo $full_command
      if eval "$full_command"  ; then
        success=true
      fi

      cd - >/dev/null
    done
    if [ "$success" = false ]; then
      UI "!!$Command $full_command"
      if [[ $force != "n" ]]; then
        return 1
      fi
    fi
  done < "$file_path"
}