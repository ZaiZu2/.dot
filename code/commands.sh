load_platform() {
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')" || return 1

  case "$OS" in
  linux | darwin) ;;
  *)
    red "Platform unsupported: $OS"
    exit 1
    ;;
  esac

  ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')" || return 1
  case "$ARCH" in
  x86_64 | arm64) ;;
  *)
    red "Architecture unsupported: $ARCH"
    exit 1
    ;;
  esac

  blue "Platform recognized as $OS-$ARCH"
  source "$SCRIPT_DIR/code/$OS.sh"
}

open_sudo_session() {
  # Invalidate any cached credentials if they are incorrect
  if sudo --non-interactive true 2>/dev/null; then
    sudo --remove-timestamp
    blue "Provide admin credentials"
  fi

  if ! sudo --validate; then
    red "This script requires admin rights"
    exit 1
  fi

  (while true; do
    sudo -n true
    sleep 60
  done) &
  SUDO_SESSION_PID=$!
  trap 'kill "$SUDO_SESSION_PID" 2>/dev/null' EXIT HUP INT QUIT TERM
}

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
      mkdir -p "$(dirname "$target_path")"
      multi "$GREEN" "Created symlink " "$BLUE" "$target_path" "$GREEN" " -> " "$BLUE" "$dotfile"
      ln -sf "$dotfile" "$target_path"
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

