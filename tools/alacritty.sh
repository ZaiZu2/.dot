is_installed_alacritty() {
  command -v alacritty >/dev/null 2>&1
}

install_linux() {
  local alacritty_url="https://github.com/alacritty/alacritty.git"
  local alacritty_repo="$XDG_DATA_HOME/alacritty"
  blue "Cloning repo $alacritty_url to $alacritty_repo"
  clone_repo "$alacritty_url" "$alacritty_repo" || return $?

  pushd "$alacritty_repo"
  blue "Building ALACRITTY"
  cargo build --release
  sudo cp 'extra/logo/alacritty-term.svg' '/usr/share/pixmaps/Alacritty.svg'
  desktop-file-install 'extra/linux/Alacritty.desktop'
  update-desktop-database
  popd
  blue "Symlinking ALACRITTY binary"
  ln -sf "$alacritty_url/target/release/alacritty" "$XDG_BIN_HOME/alacritty"
}

install_darwin() {
  brew install alacritty || {
    fail "Failed to install alacritty"
    return 1
  }
}

install_alacritty() {
  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
