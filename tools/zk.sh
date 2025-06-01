is_installed_zk() {
  command -v zk >/dev/null 2>&1
}

install_linux() {
  local zk_url="https://github.com/zk-org/zk.git"
  local zk_repo="$XDG_DATA_HOME/fzf"
  clone_repo "$zk_url" "$zk_repo"
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
