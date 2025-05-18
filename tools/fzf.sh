_install_linux() {
  fzf_repo="$XDG_DATA_HOME/fzf"
  if [ -d "$fzf_repo" ]; then
    blue "Pulling latest changes from $fzf_repo"
    git -C "$fzf_repo" fetch || warn "Failed to pull the latest $fzf_repo"
    git -C "$fzf_repo" reset --hard origin/master
  else
    local fzf_url=https://github.com/junegunn/fzf.git
    blue "Cloning repo $fzf_url to $fzf_repo"
    git clone --depth 1 "$fzf_url" "$fzf_repo" || {
      fail "Failed to clone $fzf_url"
      return
    }
  fi

  blue "Running $fzf_repo/install script"
  bash "$fzf_repo/install" --bin --no-update-rc --no-fish || {
    fail "Error occured during fzf script execution"
    return
  }
  blue "Symlinking fzf binary"
  ln -sf "$fzf_repo/bin/fzf" "$XDG_BIN_HOME/fzf"

}

is_installed_fzf() {
  command -v fzf >/dev/null 2>&1
}

install_fzf() {
  if [ "$OS" = 'darwin' ]; then
    brew install fzf || {
      fail "Failed to install fzf"
      return
    }
  elif [ "$OS" = 'linux' ]; then
    _install_linux || return $?
  fi

}
