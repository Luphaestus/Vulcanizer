Compile_Apk() {
  file=$(realpath "$1")
  mkdir -p $2
  outName=$(realpath "$2")
  cd $file
  if [[ "${file: -1}" == "/" ]]; then
    file="${file%?}"
  fi

  java -jar $EXTERNAL_DIR/apkstuff/compile/apktool.jar b -c -p res --use-aapt2 "$file"
  directory="$file/dist/"
  file_path=$(find "$directory" -maxdepth 1 -type f)
  filename=$(basename "$file_path")
  file_extension="${filename##*.}"

  if [ -z "$outName" ]; then
    outName=$(dirname "$file")$(basename "$file_path")
  else
    outName=$outName/$(basename "$file_path")
  fi

  if [[ "$file_extension" == "jar" ]]; then
    zipalign -f -v -p 4 "$file"/dist/* "$outName"
  elif [[ "$file_extension" == "apk" ]]; then
    $EXTERNAL_DIR/apkstuff/signapk/signapk $EXTERNAL_DIR/apkstuff/keys/aosp_platform.x509.pem $EXTERNAL_DIR/apkstuff/keys/aosp_platform.pk8 "$file"/dist/* "$outName"
  fi
  cd -
}

Decompile_Apk() {
  file=$(realpath "$1")
  outName="$2"
  filename=$(basename "$file")

  if [ -z "$outName" ]; then
    outName=$(dirname "$file")/"${filename%.*}"
  fi

  rm -rf $outName
  mkdir -p "$outName"
  pushd $(dirname "$outName")
  if [[ $filename == "*framework-res.apk" ]]; then
    java -jar $EXTERNAL_DIR/apkstuff/compile/apktool.jar if -p $outName "$file"
  else
    java -jar $EXTERNAL_DIR/apkstuff/compile/apktool.jar d -f -api 34 -b -p res -o $outName "$file"
    cd $outName
    if [[ $filename == *"framework.jar" ]]; then
      unzip -q "$file" "res/*" -d "./unknown"
      # CHANGE OUTNAME TO direct path
      sed -i \
        '/^doNotCompress/i \
        res\/android.mime.types: 8\n\
        res\/debian.mime.types: 8\n\
        res\/vendor.mime.types: 8' \
        "./apktool.yml"
    fi
  fi
  popd
}