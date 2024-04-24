
INDENT=""

UI() {
  local input_text="$1"
  local args="$2"
  color="${PROCESS_FG}"
  replacement=""

  if [[ "$input_text" == *"!!"* ]]; then
    color="${ERROR_FG}"
    replacement="Error: "
  elif [[ "$input_text" == !* ]]; then
    color="${WARNING_FG}"
    replacement="Warning: "
  fi

  if [[ "$input_text" == *"!!"* ]] || [[ "$input_text" == !* ]]; then
    modified_text=$(echo "$input_text" | sed "s/!!/Error: /" | sed "s/^!/$replacement/")
    printf "${color}%s${RESET}\n" "$modified_text"
  elif [[ "${input_text:0:2}" == "h|" ]]; then
    tput bold 
    
    input_text="${input_text:2}"
    local text_length=${#input_text}
    local padding_size=$((TITLEWIDTH - text_length))
    local left_padding_size=$((padding_size / 2))
    local right_padding_size=$((padding_size - left_padding_size))
    left_padding=$(printf "%$((left_padding_size - 1))s" "" | tr ' ' '-')
    right_padding=$(printf "%$((right_padding_size - 1))s" "" | tr ' ' '-')   
     printf "${HEADING_BG}${HEADING_FG}%s%s%s%s${RESET}\n" \
      "$INDENT" "$left_padding" " $input_text " "$right_padding"
    tput sgr0
  elif [[ "${input_text:0:2}" == "t|" ]]; then
    tput bold 
    input_text="${input_text:2}"
    local text_length=${#input_text}
    local padding_size=$((TITLEWIDTH - text_length))
    local left_padding_size=$((padding_size / 2))
    local right_padding_size=$((padding_size - left_padding_size))
    local left_padding=$(printf "%${left_padding_size}s" "")
    local right_padding=$(printf "%${right_padding_size}s" "")
    printf "${TITLE_BG}${TITLE_FG}%s%s%s%s${RESET}\n" \
      "$INDENT" "$left_padding" "$input_text" "$right_padding"
    tput sgr0
  elif [[ "$input_text" == "d" ]]; then
    echo -e $args "${SUCCESS_FG} Done! ${RESET}"
  elif [[ "$input_text" == "f" ]]; then
    echo -e $args "${ERROR_FG} Failed! ${RESET}"
  else
    left_of_colon="${input_text%%:*}"
    right_of_colon="${input_text#*:}"

    if [[ "$left_of_colon" == "$input_text" ]]; then
      printf "$INDENT${color}%s${RESET} $args" "$input_text"
    else
      printf "$INDENT${color}%s${RESET}:%s $args" "$left_of_colon" "$right_of_colon"
    fi
  fi
}

