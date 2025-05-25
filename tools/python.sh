is_installed_python() {
  command -v python3 >/dev/null 2>&1
}

install_linux() {
  sudo apt install bat || {
    fail "Failed to install BAT"
    return 1
  }
  sudo ln -sf "/usr/bin/batcat" "/usr/bin/bat"
  bat cache --build
}

install_darwin() {
  brew install bat || {
    fail "Failed to install BAT"
    return 1
  }
  bat cache --build
}

install_python() {
  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
