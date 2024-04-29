#!/bin/bash
set -e

COMMON_COMMANDS=()
LATE_COMMON_COMMANDS=()

CONFIG=./config.sh
. $CONFIG

if [ "$FOR_EXYNOS" = "y" ]; then
  TARGET=$EXYNOS_TARGET
  MODEL=("${EXYNOS_MODELS[@]}")
else
  TARGET=$SNAPDRAGON_TARGET
  MODEL=("${SNAPDRAGON_MODELS[@]}")
fi

UI=$HELPER_DIR/UI.sh
. $UI

if [ "$EUID" -ne 0 ]; then
  UI "!Vulcanizer be run as root. Re-running with sudo..."
  exec sudo "$0" "$@"
fi

if [ ${#MODEL[@]} -eq 1 ] && [[ $COMMON == "y" ]]; then
  UI "!Common images only work with two or more vendors, turning off..."
  COMPRESS="n"
fi

rm -rf $SPECIFIC_FILES
rm -rf $OUT_DIR

UI "t|Loading Scripts"
for script in $(find $ASSETS_DIR -type f -name "*.sh"); do
  UI "Loading: $(basename "$script")"
  . $script
  UI "d"
done
for cmd in "${COMMON_COMMANDS[@]}"; do
  echo " "
  eval "$cmd"
done

for cmd in "${LATE_COMMON_COMMANDS[@]}"; do
  echo " "
  eval "$cmd"
done


