#!/bin/bash
set -e

COMMON_COMMANDS=()

CONFIG=./config.sh
. $CONFIG
UI=$HELPER_DIR/UI.sh
. $UI

if [ "$EUID" -ne 0 ]; then
  UI "!Vulcanizer be run as root. Re-running with sudo..."
  exec sudo "$0" "$@"
fi

UI "t|Loading Scripts"
for script in $(find $ASSETS_DIR -type f -name "*.sh"); do
  UI "Loading: $(basename "$script")"
  . $script
  UI "d"
done

for cmd in "${COMMON_COMMANDS[@]}"; do
    UI "Running: $cmd..."
    eval "$cmd"
done