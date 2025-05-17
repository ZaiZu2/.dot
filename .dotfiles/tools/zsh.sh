is_installed_zsh() {
  command -v zsh >/dev/null 2>&1
}

install_linux() {
  sudo apt install zsh || {
    fail "Failed to install ZSH"
    return
  }
  sudo chsh -s /bin/zsh

  local ohmypost_file=$(mktemp -u)
  curl -fsSL -o "$ohmypost_file" "https://ohmyposh.dev/install.sh"
  ohmypost_code=$?
  if [ ! $ohmypost_code ]; then
    warn "Failed to download Oh-my-posh script"
  else
    bash "$ohmypost_file" -- -d "$XDG_DATA_HOME" || warn "Error occured while executing Oh-my-posh script"
  fi
  rm -f "$ohmypost_file"
}

install_darwin() {
  brew install jandedobbeleer/oh-my-posh/oh-my-posh || warn "Failed to install Oh-my-posh"
}

install_zsh() {
  if [ "$OS" = 'darwin' ]; then
    install_darwin
  elif [ "$OS" = 'linux' ]; then
    install_linux
  fi

  local zinit_file=$(mktemp -u)
  curl -fsSL -o "$zinit_file" "https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh"
  zinit_code=$?
  if [ ! $zinit_code ]; then
    warn "Failed to download Zinit script"
  else
    bash "$zinit_file" -- -d "$XDG_DATA_HOME" || warn "Error occured while executing Zinit script"
  fi
  rm -f "$zinit_file"
}
