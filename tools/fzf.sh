deps_fzf() {
  echo ''
}

is_installed_fzf() {
  command -v fzf >/dev/null 2>&1
}

install_fzf() {
  _install_linux() {
    local fzf_url=https://github.com/junegunn/fzf.git
    local fzf_repo="$XDG_DATA_HOME/fzf"
    clone_repo "$fzf_url" "$fzf_repo"

    blue "Running $fzf_repo/install script"
    bash "$fzf_repo/install" --bin --no-update-rc --no-fish || {
      fail "Error occured during fzf script execution"
      return
    }
    blue "Symlinking fzf binary"
    ln -sf "$fzf_repo/bin/fzf" "$XDG_BIN_HOME/fzf"

  }

  if [ "$OS" = 'darwin' ]; then
    brew install fzf || {
      fail "Failed to install fzf"
      return
    }
  elif [ "$OS" = 'linux' ]; then
    _install_linux || return $?
  fi

}
