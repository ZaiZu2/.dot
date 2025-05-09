_install_brew() {
  curl -fsSL "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" &&
    NONINTERACTIVE=1 bash -s

  brew install cmake curl pkg-config libtool unzip ripgrep \
    build-essential libreadline-dev gnu-tar coreutils
}

init_pkg_mgr() {
  if ! command -v brew >/dev/null 2>&1; then
    _install_brew || return 1
  fi

  brew update || return 1
}

install_font() {
  cp "$SCRIPT_DIR/files/font/"* /Library/Fonts
  chmod 644 /Library/Fonts/*
  blue "Installed fonts"
}
