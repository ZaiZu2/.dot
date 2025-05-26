_install_brew() {
  blue "Downloading BREW script"
  brew_file=$(mktemp)
  curl -fsSL -o "$brew_file" "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" || {
    multi "$RED" "Failed to download " "$BLUE" "BREW"
    return 1
  }
  blue "Executing BREW script"
  NONINTERACTIVE=1 bash "$brew_file" || {
    multi "$RED" "Error occured while executing " "$BLUE" "BREW" "$RED" " script"
    return 1
  }
  rm "$brew_file"

  blue "Installing system packages"
  brew install cmake curl pkg-config libtool unzip ripgrep jq \
    build-essential libreadline-dev gnu-tar coreutils
}

init_pkg_mgr() {
  if ! command -v brew >/dev/null 2>&1; then
    _install_brew || return 1
  fi

  blue "Updating BREW"
  brew update || {
    multi "$YELLOW" "Error occured while updating " "$BLUE" "BREW"
  }
}

copy_font() {
  cp "$SCRIPT_DIR/files/font/"* '/Library/Fonts'
  chmod 0644 '/Library/Fonts/'*
  blue 'Installing fonts'
}
