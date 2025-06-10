deps_gh() {
  echo ''
}

is_installed_gh() {
  command -v gh >/dev/null 2>&1
}

install_gh() {
  install_linux() {
    sudo apt install gh || {
      fail "Failed to install GH"
      return 1
    }
  }

  install_darwin() {
    brew install gh || {
      fail "Failed to install GH"
      return 1
    }
  }

  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
