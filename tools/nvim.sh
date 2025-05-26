is_installed_nvim() {
  command -v nvim >/dev/null 2>&1
}

install_linux() {
  local nvim="nvim-${OS}-${ARCH}"
  curl -fsSL -o "/tmp/$nvim.tar.gz" \
    "https://github.com/neovim/neovim/releases/latest/download/$nvim.tar.gz" || {
    fail 'Failed to download nvim'
    return
  }
  sudo tar -C "$XDG_DATA_HOME" -xzf "/tmp/$nvim.tar.gz" || {
    fail 'Failed to extract archive'
    return
  }
  chmod 0755 "$XDG_DATA_HOME/$nvim/bin/nvim"
  sudo rm -f "/tmp/$nvim.tar.gz" 2>/dev/null
  blue "Symlinking GO binary"
  sudo ln -sf "$XDG_DATA_HOME/$nvim/bin/nvim" "/usr/local/bin/nvim"
}

install_darwin() {
  brew install nvim || {
    fail 'Failed to install NVIM'
    return
  }
}

install_nvim() {
  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
