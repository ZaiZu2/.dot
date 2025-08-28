deps_zk() {
  echo 'git,go'
}

is_installed_zk() {
  command -v zk >/dev/null 2>&1
}

install_zk() {
  install_linux() {
    local zk_url="https://github.com/zk-org/zk.git"
    local zk_repo="$XDG_DATA_HOME/zk"
    clone_repo "$zk_url" "$zk_repo"
    pushd "$zk_repo"
    blue "Building ZK binary"
    make || {
      fail 'Failed to build ZK'
      return 1
    }

    popd
    blue "Symlinking ZK binary"
    ln -sf "$zk_repo/zk" "$XDG_BIN_HOME/zk"
  }

  install_darwin() {
    brew install zk || {
      fail 'Failed to install ZK'
      return 1
    }
  }

  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
