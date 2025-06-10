deps_python() {
  echo ''
}

is_installed_python() {
  command -v python3 >/dev/null 2>&1
}

install_python() {
  install_linux() {
    sudo apt install python3 || {
      fail "Failed to install PYTHON"
      return 1
    }
  }

  install_darwin() {
    brew install python3 || {
      fail "Failed to install PYTHON"
      return 1
    }
  }

  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
