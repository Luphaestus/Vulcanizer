Compare_Cheksum()
{
    old_checksum=""
    if [ -f "$1" ]; then
      old_checksum=$(md5sum "$1" | awk '{print $1}')
    fi
    
    new_checksum=""
    if [ -f "$2" ]; then
      new_checksum=$(md5sum "$2" | awk '{print $1}')
    fi
    
    if [[ "$old_checksum" == "$new_checksum" ]]; then
      return 0
    else
      return 1
    fi
}