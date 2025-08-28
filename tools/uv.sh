deps_uv() {
  echo ''
}

is_installed_uv() {
  command -v uv >/dev/null 2>&1
}

install_uv() {
  install_linux() {
    local script_file=$(mktemp -u)
    blue "Downloading install script"
    curl -fsSL -o "$script_file" https://astral.sh/uv/install.sh || {
      fail "Failed to download the script"
      return 1
    }
    blue "Running install script"
    UV_NO_MODIFY_PATH=1 bash "$script_file" || {
      fail "Error occurred while executing the script"
      return 1
    }
    rm -f "$script_file"
  }

  install_darwin() {
    UV_NO_MODIFY_PATH=1 brew install uv || {
      fail "Failed to install UV"
      return 1
    }
  }

  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
