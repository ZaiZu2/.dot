deps_jq() {
  echo ''
}

is_installed_jq() {
  command -v jq >/dev/null 2>&1
}
install_jq() {
  install_linux() {
    sudo apt install --yes jq || {
      fail "Failed to install JQ"
      return 1
    }
  }

  install_darwin() {
    brew install jq || {
      fail "Failed to install JQ"
      return 1
    }
  }

  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
