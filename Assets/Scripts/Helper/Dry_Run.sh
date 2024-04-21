Dry_Run() {
  local total_args=$#

  local last_arg="${!total_args}"

  local command=("${@:1:$total_args}")

  if [[ "$last_arg" != "y" ]]; then
    command_str=$(printf " %s" "${command[@]}")
    bash -c "$command_str"
  fi
}