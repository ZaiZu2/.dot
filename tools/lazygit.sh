is_installed_lazygit() {
  command -v lazygit >/dev/null 2>&1 || return 1

  local lazygit_api='https://api.github.com/repos/jesseduffield/lazygit'
  _latest_version="$(curl -fsSL "$lazygit_api/releases/latest" | jq '.tag_name')"
  _latest_version=${_latest_version:2:-1}
  _current_version="$(lazygit --version | sed -n 's/.*version=\([0-9.]*\),.*/\1/p')"

  if [ ! "$_latest_version" = "$_current_version" ]; then
    yellow "New LAZYGIT version available - $_latest_version"
    return 1
  fi
}

install_linux() {
  local cap_os="$(echo "${OS:0:1}" | tr '[:lower:]' '[:upper:]')${OS:1}"
  local filename="lazygit_${_latest_version}_${cap_os}_${ARCH}.tar.gz"
  local binary_url="https://github.com/jesseduffield/lazygit/releases/download/v$_latest_version/$filename"
  blue "Downloading LAZYGIT archive from '$binary_url'"
  curl -fsSL -o "/tmp/$filename" "$binary_url" || {
    fail "Failed to download the archive"
    return 1
  }
  blue "Extracting '$filename' to '$XDG_BIN_HOME'"
  tar -C "$XDG_BIN_HOME" -xzf "/tmp/$filename" || {
    fail "Failed to extract the archive"
    return 1
  }
  blue "Removing temporary archive"
  rm "/tmp/$filename"
}

install_darwin() {
  brew install lazygit || {
    fail "Failed to install LAZYGIT"
    return 1
  }
}

install_lazygit() {
  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
