get_shell() {
  if [ -n "$BASH_VERSION" ]; then
    echo bash
  elif [ -n "$ZSH_VERSION" ]; then
    echo zsh
  else
    red "Could not recognize shell"
    exit 1
  fi
}

get_script_dir() {
  shell="$(get_shell)"
  if [ "$shell" = 'bash' ]; then
    dirname "$(realpath "${BASH_SOURCE[0]}")"
  elif [ "$shell" = 'zsh' ]; then
    dirname "$(realpath "${(%):-%x}"))"
  fi
}

green() {
  if [ $# -ge 2 ]; then
    label=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    echo -e "\033[1;32m$label\033[1;34m ${*:2}\033[0m"
  else
    echo -e "\033[1;32m$1\033[0m"
  fi
}

blue() {
  if [ $# -ge 2 ]; then
    label=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    echo -e "\033[1;34m$label\033[1;34m ${*:2}\033[0m"
  else
    echo -e "\033[1;34m$1\033[0m"
  fi
}

red() {
  if [ $# -ge 2 ]; then
    label=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    echo -e "\033[1;31m$label\033[1;34m ${*:2}\033[0m"
  else
    echo -e "\033[1;31m$1\033[0m"
  fi
}

yellow() {
  if [ $# -ge 2 ]; then
    label=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    echo -e "\033[1;33m$label\033[1;34m ${*:2}\033[0m"
  else
    echo -e "\033[1;33m$1\033[0m"
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
  tool_name=$1
  tool_path=$(realpath "./tools/$tool_name.sh")
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
