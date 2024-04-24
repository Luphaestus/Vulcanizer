Vendor_C2x_Manifest()
{
    manifestxml="etc/vintf/manifest.xml"

   manifesttextlabel=$(ls -dZ "$manifestxml")
   selabelmanifest=$(echo "$manifesttextlabel" | cut -d " " -f1)

   start=$(grep -n "\<name>vendor\.samsung\.hardware\.biometrics\.face</name\>" "$manifestxml" | awk -F: '{print $1+1}')
   first=$(sed -n "${start},\$p" "$manifestxml" | grep -n "2.0" | head -n 1 | awk -F: '{print $1}')
   seccond=$(sed -n "${start},\$p" "$manifestxml" | grep -n "@2.0" | head -n 1 | awk -F: '{print $1}')
   firsttotal=$((start + first-2))
   seccondtotal=$((start + seccond))
   sed -i "$firsttotal a\        <version>3.0</version>" "$manifestxml"
   sed -i "$seccondtotal a\        <fqname>@3.0::ISehBiometricsFace/default</fqname>" "$manifestxml"
   echo  "manifest.xml : $firsttotal"
   echo "manifest.xml : $seccondtotal"

   deleteTag "\<name>vendor\.samsung\.hardware\.security\.wsm</name\>"
   deleteTag  "android\.hardware\.vibrator"
   deleteTag "vendor.samsung.hardware.tlc.blockchain"
   deleteTag "vendor\.samsung\.hardware\.tlc\.payment"
   deleteTag "vendor\.samsung\.hardware\.tlc\.uc"
   chcon $selabelmanifest $manifestxml
}