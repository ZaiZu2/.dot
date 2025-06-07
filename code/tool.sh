fail() {
  msg=$1
  echo 1 >"$CURR_TOOL_STATUS"
  [ "$msg" ] && red "$msg"
}

finish() {
  msg=$1
  echo 0 >"$CURR_TOOL_STATUS"
  [ "$msg" ] && green "$msg"
}

warn() {
  msg=$1
  echo 10 >"$CURR_TOOL_STATUS"
  [ "$msg" ] && yellow "$msg"
}

process_installation() {
  format_line() {
    local status_code=$1
    local message=$2
    if [ $((status_code)) -eq 0 ]; then # INFO
      multi "$GREEN" "┃" "$DEFAULT" "$message"
    elif [ $((status_code)) -eq 10 ]; then # WARN
      multi "$YELLOW" "┃" "$DEFAULT" "$message"
    else # ERROR
      multi "$RED" "┃" "$DEFAULT" "$message"
    fi
  }

  build_end() {
    local status_code="$(<"$CURR_TOOL_STATUS")"
    if [ $((status_code)) -eq 0 ]; then
      green "┗━━━ SUCCESS ━━━━"
    elif [ $((status_code)) -eq 10 ]; then
      yellow "┗━━━ WARNING ━━━━"
    else
      red "┗━━━ FAILED ━━━━"
    fi

  }

  tool="$1"
  install_fn="$2"

  CURR_TOOL="$tool"
  CURR_TOOL_STATUS=$(mktemp) && echo 0 >"$CURR_TOOL_STATUS"
  mkdir -p "$LOGS_DIR"
  : >"$LOGS_DIR/$CURR_TOOL.log" # 'Reinitialize' (truncate) existing log file

  local pipe=$(mktemp -u) && mkfifo "$pipe"

  # Background process responsible for live processing individual tool installation logs
  {
    while IFS= read -r line; do
      format_line "$(<"$CURR_TOOL_STATUS")" "$line"
      echo "$line" >>"$LOGS_DIR/$CURR_TOOL.log"
    done <"$pipe"
  } &
  local parser_pid=$!

  multi "$GREEN" "┏━━━ " "$BLUE" "$(cap "$tool")" "$GREEN" " - installing... ━━━━"
  # Foreground `install_*` function to which background process listens to
  "$install_fn" >"$pipe" 2>&1
  wait $parser_pid
  build_end

  local final_status=$(($(<"$CURR_TOOL_STATUS")))
  rm -f "$pipe" "$CURR_TOOL_STATUS" &>/dev/null
  return $final_status
}

install_tools() {
  local excluded="$1"
  local only="$2"
  local force="$3"

  for file in "$SCRIPT_DIR/tools/"*; do
    source "$file"
    local tool="$(basename -s '.sh' "$file")"

    # Iterate over select tools if --only was set
    [[ -n "${only:-}" && ",$only," != *",$tool,"* ]] && continue
    # Skip excluded tools
    [[ ${excluded+x} && ",$excluded," == *",$tool,"* ]] && continue

    local is_installed_fn="is_installed_$tool"
    local install_fn="install_$tool"
    check_fn "$is_installed_fn" "$install_fn" || return 1

    if ! "$is_installed_fn" || [ "$force" = true ]; then
      process_installation "$tool" "$install_fn"
    else
      multi "$YELLOW" " ━━━ " "$BLUE" "$(cap "$tool")" "$YELLOW" " is already installed ━━━"
    fi
  done
}

clone_repo() {
  local repo_url=$1
  local repo_dir=$2

  local default_branch=$(git remote show origin | sed -n 's/.*HEAD branch: //p')

  if [ -d "$repo_dir" ]; then
    blue "Pulling latest changes from $repo_url#$default_branch"
    git -C "$repo_dir" fetch || warn "Failed to pull the latest $repo_dir"
    git -C "$repo_dir" reset --hard "origin/$default_branch"
  else
    blue "Cloning repo $repo_url to $repo_dir"
    git clone --depth 1 "$repo_url" "$repo_dir" || {
      fail "Failed to clone $repo_url"
      return 1
    }
  fi
}
