symlink_dotfiles() {
  local force=${1-false}

  for dotfile in "$DOTFILES_DIR"/**/*; do
    [ -d "$dotfile" ] && continue

    local rel_path=${dotfile##"$DOTFILES_DIR/"}
    local target_path="$HOME/$rel_path"
    if [[ -f "$target_path" && "$force" = false ]]; then
      multi "$YELLOW" "Skipping " "$BLUE" "$target_path" "$YELLOW" ", file already exists"
    elif [[ -L "$target_path" && "$force" = false ]]; then
      multi "$YELLOW" "Skipping " "$BLUE" "$target_path" "$YELLOW" ", symlink already exists"
    else
      mkdir -p "$(dirname $target_path)"
      ln -sf "$dotfile" "$target_path"
    fi
  done
}

setup() {
  local excluded="${1-}"
  local only="${2-}"
  local force="${3-false}"
  local skip_pkg_mgr="${4-false}"

  symlink_dotfiles "$force"
  open_sudo_session
  install_font
  [ "$skip_pkg_mgr" = true ] || init_pkg_mgr || return $?
  install_tools "$excluded" "$only" "$force"
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
		  brew install ${tool} || {
		    fail "Failed to install ${tool}"
		    return 1
		  }
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
