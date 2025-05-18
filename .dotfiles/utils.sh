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
  for fn in "${@:2}"; do
    if ! declare -f "$fn" >/dev/null; then
      red "$1" "Function '$fn' does not exist"
      return 1
    fi
  done
}

create_tool_template() {
  local tool_name=$1
  local tool_path=$(realpath "$SCRIPT_DIR/tools/$tool_name.sh")
  if [ -f "$tool_path" ]; then
    red "$tool_name" "Template not created - tool already exists"
    return 1
  fi

  touch "$tool_path"
  # Tabs with `-EOF` allow to indent here-doc without injecting indentation into file
  cat >"./tools/${tool_name}.sh" <<-EOF
		is_installed_${tool_name}() {
		  command -v ${tool_name} >/dev/null 2>&1;
		}

		install_linux() {

		}

		install_darwin() {

		}

		install_${tool_name}() {
		  if [ "\$OS" = 'darwin' ]; then
		    install_darwin || return 1
		  elif [ "\$OS" = 'linux' ]; then
		    install_linux || return 1
		  fi
		}
	EOF
  chmod +x "$tool_path"
  blue "$tool_name" "Template created at $tool_path"
}
