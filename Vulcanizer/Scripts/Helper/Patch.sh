SeSed() {
  # Last argument is the directory
  dir="${!#}"
  # All other arguments form the sed command
  commands="${@:1:$(($#-1))}"
  # Get the SELinux context
  textlabel=$(ls -dZ "$dir")
  selabel=$(echo "$textlabel" | cut -d " " -f1)


  # Execute the sed command with proper formatting
  echo "Executing sed with: sed $commands" $dir
  sed $commands $dir

  # Set the original SELinux context back
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
      if eval "$full_command 2>/dev/null"  ; then
        success=true
      fi

      cd - >/dev/null
    done
    if [ "$success" = false ]; then
      if [[ $force != "n" ]]; then
        echo -ne $OVERWRITE
        UI "!!$Command $full_command"
        return 1
      else
        echo -ne $OVERWRITE
        UI "!Failed to Execute '$Command $full_command'"
      fi

    fi
  done < "$file_path"
  echo -ne $OVERWRITE

}