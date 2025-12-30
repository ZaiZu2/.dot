deps_zoxide() {
  echo ''
}

is_installed_zoxide() {
  command -v zoxide >/dev/null 2>&1;
}

install_zoxide() {
  # Must be nested within 'install_zoxide' function to not polute global scope during sourcing
  install_linux() {
    local script_file=$(mktemp -u)
    blue "Downloading install script"
    curl -fsSL -o "$script_file" https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh || {
      fail "Failed to download the script"
      return
    }
    blue "Running install script"
    bash "$script_file" || {
      fail "Error occurred while executing the script"
      return
    }
    rm -f "$script_file"
  }

  install_darwin() {
     brew install zoxide || {
       fail "Failed to install zoxide"
     return 1
     }
  }

  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
