Is_Extracted()
{
 mount_dir=$1
 if [ -d "$mount_dir" ]; then
   if ! findmnt -r -n -o TARGET | grep -q "^$mount_dir$"; then
     if [ "$(ls -A "$mount_dir")" ]; then
       return 0
     fi
   fi
 fi
 return 1
}