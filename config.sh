#Common
COMPRESS="n"
FOR_EXYNOS="y"
EROFS="n"

#Exnos
EXYNOS_TARGET="p3s"
EXYNOS_MODELS=("c1s" c2s c1slte c2slte)
#EXYNOS_MODELS=(c2slte c2s)

#Snapdragon
SNAPDRAGON_TARGET="something"
SNAPDRAGON_MODELS=(c2s)

#Vendor
CREATE_VENDOR="y"
COMMON_VENDOR="n"
PATCH_VENDOR="y"
FORCE_VENDOR="n"
#test
SKIPVENDORCHECKSUM="n"

VENDOR_DELETE="C2xDelete"
VENDOR_COPY="C2xCopy"
VENDOR_MISC="C2xMisc"


#Project Structure
ROOT_DIR=$(dirname "$(readlink -f "$0")")
WORKING_DIR=$ROOT_DIR/Working
EXTERNAL_DIR=$ROOT_DIR/External
STOCK_DIR=$ROOT_DIR/Stock
ASSETS_DIR=$ROOT_DIR/Vulcanizer
RESOURCES_DIR=$ASSETS_DIR/Resources
SCRIPT_DIR=$ASSETS_DIR/Scripts
HELPER_DIR=$SCRIPT_DIR/Helper
MODIFICATION_DIR=$SCRIPT_DIR/Modifications
SPECIFIC_FILES=$WORKING_DIR/ODM/SpecificFiles
OUT_DIR=$ROOT_DIR/Out

#Formating
INDENT_ALT="   - "
TITLEWIDTH=45

RESET="\033[0m"
SUCCESS_FG="\033[32m"
TITLE_BG="\033[104m"
TITLE_FG="\033[30m"
PROCESS_FG="\033[95m"
ERROR_FG="\033[31m"
WARNING_FG="\033[33m"
NO_FORMAT="\033[0m"
HEADING_FG="\033[38;5;14m"
#HEADING_BG="\033[48;5;252m"

OVERWRITE="\r\033[K"

#echo -e '\033k'"Vulcanizer"'\033\\'
echo -e '\033]2;'"Vulcanizer"'\007'

