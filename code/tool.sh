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

list_tools() {
  for file in "$SCRIPT_DIR/tools/"*; do
    basename -s '.sh' "$file"
  done | tr '\n' ' '
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

CALL_STACK=''
INSTALL_ORDER=''

# Build a dependency list by recursing into each tool's dependency list. Detect cyclic
# dependencies and notify user.
build_install_list() {
  local tool=$1
  local deps_fn="deps_$tool"
  local deps=$($deps_fn | tr ',' ' ')

  if [[ "$CALL_STACK " == *" $tool "* ]]; then
    local tmp=${CALL_STACK:1}
    red "Cyclic dependency detected [${tmp//,/ -> } -> $tool]. Check dependencies of the tools in the cycle."
    return 1
  fi

  if [[ "$INSTALL_ORDER " == *" $tool "* ]]; then
    return 0
  fi

  CALL_STACK+=" $tool"

  for dep in $deps; do
    build_install_list "$dep"
  done

  CALL_STACK="${CALL_STACK/" $tool"/}"
  INSTALL_ORDER+=" $tool"
}

install_tools() {
  local excluded="$1"
  local only="$2"
  local force="$3"

  # Source all tools so all context is available for building dependency list
  tools=''
  for file in "$SCRIPT_DIR/tools/"*; do
    source "$file"
    local tool="$(basename -s '.sh' "$file")"
    tools="$tools $tool"
  done

  # Build dependency list only for tools specified by a user
  for tool in $tools; do
    # Iterate over select tools if --only was set
    [[ -n "${only:-}" && " $only " != *" $tool "* ]] && continue
    # Skip excluded tools
    [[ ${excluded+x} && " $excluded " == *" $tool "* ]] && continue

    build_install_list "$tool"
  done

  echo "INSTALL_ORDER = $INSTALL_ORDER"
  # Iterate over dependency list, installing tools
  for tool in $INSTALL_ORDER; do
    local is_installed_fn="is_installed_$tool"
    local install_fn="install_$tool"
    local deps_fn="deps_$tool"
    check_fn "$is_installed_fn" "$install_fn" "$deps_fn" || return 1

    if ! "$is_installed_fn" || [ "$force" = true ]; then
      process_installation "$tool" "$install_fn"
    else
      multi "$YELLOW" " ━━━ " "$BLUE" "$(cap "$tool")" "$YELLOW" " is already installed ━━━"
    fi
  done
}
