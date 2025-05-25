is_installed_zk() {
  command -v zk >/dev/null 2>&1
}

install_linux() {
  zk_url="https://github.com/zk-org/zk.git"
  zk_repo="$XDG_DATA_HOME/fzf"
  blue "Cloning repo $zk_url to $zk_repo"
  git clone --depth 1 "$zk_url" "$zk_repo" || {
    fail "Failed to clone $zk_url"
    return
  }
  pushd "$zk_repo"
  make
  popd
  blue "Symlinking ZK binary"
  ln -sf "$zk_repo/zk/zk" "$XDG_BIN_HOME/zk"
}

install_darwin() {
  brew install nvim || {
    fail 'Failed to install ZK'
    return 1
  }
}

install_zk() {
  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
