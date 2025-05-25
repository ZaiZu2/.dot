is_installed_tmux() {
  command -v tmux >/dev/null 2>&1
}

install_linux() {
  sudo apt install tmux || {
    fail "Failed to install TMUX"
    return 1
  }

}

install_darwin() {
  brew install tmux || {
    fail "Failed to install TMUX"
    return 1
  }
}

install_tmux() {
  blue "Installing TMUX"
  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi

  # Install TPM
  local tpm_repo="$XDG_CONFIG_HOME/tmux/plugins/tpm"
  local tpm_url="https://github.com/tmux-plugins/tpm"
  if [ -d "$tpm_repo" ]; then
    blue "Pulling latest TPM changes from $tpm_repo"
    git -C "$tpm_repo" fetch || warn "Failed to pull the latest $tpm_repo"
    git -C "$tpm_repo" reset --hard origin/master
  else
    blue "Cloning TPM repo $tpm_url to $tpm_repo"
    git clone --depth 1 "$tpm_url" "$tpm_repo" || {
      fail "Failed to clone $tpm_url"
      return 1
    }
  fi
  blue "Installing TPM plugins"
  bash "$tpm_repo/bin/install_plugins"
}
