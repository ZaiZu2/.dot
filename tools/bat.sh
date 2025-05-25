is_installed_bat() {
  command -v bat >/dev/null 2>&1
}

install_linux() {
  sudo apt install bat || {
    fail "Failed to install BAT"
    return 1
  }
}

install_darwin() {
  brew install bat || {
    fail "Failed to install BAT"
    return 1
  }
}

install_bat() {
  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
