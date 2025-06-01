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
  clone_repo "$tpm_url" "$tpm_repo"
  blue "Installing TPM plugins"
  bash "$tpm_repo/bin/install_plugins"
}
