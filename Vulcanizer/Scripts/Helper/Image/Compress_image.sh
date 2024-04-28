Compress_Image()
{
  echo " "
  local image=$1
  local root_path=$(dirname "$image")
  local out_path=$root_path/compressed/
  rm -rf $out_path
  mkdir -p $out_path
  local name=$(basename "$image")
  UI "h|Compressing $name"
  UI "Creating: $name sparse image"
  img2simg "$image" "$out_path/sparse.img"
  UI "d"
  UI "Converting: Android sparse image to a raw image"
  echo 4 | img2sdat -o "$out_path" -p "$name" "$out_path/sparse.img" > /dev/null
  UI "d"
  size=$(( $(wc -c < "$image")))
  rm "$out_path/sparse.img"
  UI "Compressing: $name"
  brotli -q 5 "$out_path/$name.new.dat" -o "$out_path/$name.new.dat.br"
  UI "d"
  rm "$out_path/$name.new.dat"
  echo "resize $img $size" >> "$out_path/op_list"
}