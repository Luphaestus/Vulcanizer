#!/bin/bash

# Define the directory containing the files to delete
DIRECTORY="$1"

# Define the list of files to delete
FILES=(
"bin/cass"
"bin/vaultkeeperd"
"etc/init/pa_daemon_teegris.rc"
"etc/init/cass.rc"
"etc/init/vaultkeeper_common.rc"
"etc/init/vendor_flash_recovery.rc"
"etc/vintf/manifest/vaultkeeper_manifest.xml"
"etc/dpolicy"
"recovery-from-boot.p"
"etc/init/vendor.samsung.hardware.biometrics.face@2.0-service.rc"
"etc/vintf/manifest/vendor.samsung.hardware.tlc.ddar@1.0-manifest.xml"
"etc/vintf/manifest/vendor.samsung.hardware.tlc.hdm@1.1-manifest.xml"
"etc/vintf/manifest/vendor.samsung.hardware.tlc.iccc@1.0-manifest.xml"
"etc/vintf/manifest/vendor.samsung.hardware.tlc.snap@1.0-manifest.xml"
"bin/install-recovery.sh"
"bin/hw/vendor.samsung.hardware.tlc.blockchain@1.0-service"
"bin/hw/vendor.samsung.hardware.tlc.ddar@1.0-service"
"bin/hw/vendor.samsung.hardware.tlc.hdm@1.1-service"
"bin/hw/vendor.samsung.hardware.tlc.iccc@1.0-service"
"bin/hw/vendor.samsung.hardware.tlc.payment@1.0-service"
"bin/hw/vendor.samsung.hardware.tlc.snap@1.0-service"
"bin/hw/vendor.samsung.hardware.tlc.ucm@2.0-service"
"lib64/vendor.samsung.hardware.vibrator@2.0.so"
"lib64/vendor.samsung.hardware.vibrator@2.1.so"
"lib64/vendor.samsung.hardware.vibrator@2.2.so"
"bin/hw/vendor.samsung.hardware.vibrator@2.2-service"
"etc/init/vendor.samsung.hardware.vibrator@2.2-service.rc"
)

# Loop through the files and delete them
for FILE in "${FILES[@]}"
do
    FULL_PATH="$DIRECTORY/$FILE"
    if [ -e "$FULL_PATH" ]; then
        rm "$FULL_PATH"
        echo "Deleted: $FULL_PATH"
    else
        echo "File not found: $FULL_PATH"
    fi
done
