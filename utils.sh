get_shell() {
  if [ -n "$BASH_VERSION" ]; then
    echo bash
  elif [ -n "$ZSH_VERSION" ]; then
    echo zsh
  else
    red "Program only supports Zsh and Bash"
    exit 1
  fi
}

setup_shell() {
  if [  "$USED_SHELL" = 'bash'  ]; then
    shopt -s globstar dotglob
  elif [ "$USED_SHELL" = 'zsh' ]; then
    setopt dotglob
  fi
}

get_script_dir() {
  local shell="$USED_SHELL"
  if [ "$shell" = 'bash' ]; then
    dirname "$(realpath "${BASH_SOURCE[0]}")"
  elif [ "$shell" = 'zsh' ]; then
    dirname "$(realpath "${(%):-%x}"))"
  fi
}

check_fn() {
  for fn in "$@"; do
    if ! declare -f "$fn" >/dev/null; then
      red "Function '$fn' does not exist"
      return 1
    fi
  done
}

create_tool_template() {
  local tool=$1
  local cap_tool="$(cap "$tool")"
  local tool_path=$(realpath "$SCRIPT_DIR/tools/$tool.sh")

  if [ -f "$tool_path" ]; then
    multi "$BLUE" "$cap_tool" "$RED" " already exists, template not created"
    return 1
  fi

  touch "$tool_path"
  # Tabs with `-EOF` allow to indent here-doc without injecting indentation into file
  cat >"./tools/${tool}.sh" <<-EOF
		is_installed_${tool}() {
		  command -v ${tool} >/dev/null 2>&1;
		}

		install_linux() {

		}

		install_darwin() {

		}

		install_${tool}() {
		  if [ "\$OS" = 'darwin' ]; then
		    install_darwin || return 1
		  elif [ "\$OS" = 'linux' ]; then
		    install_linux || return 1
		  fi
		}
	EOF
  chmod +x "$tool_path"
  multi "$GREEN" "Template created for " "$BLUE" "$cap_tool" \
    "$GREEN" " at " "$BLUE" "$tool_path"
}

cap() {
  tr '[:lower:]' '[:upper:]' <<<"$1"
}
