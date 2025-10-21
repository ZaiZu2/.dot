deps_zsh() {
  echo 'git,go'
}

is_installed_zsh() {
  command -v zsh >/dev/null 2>&1
}

install_zsh() {
  install_linux() {
    sudo apt install zsh || {
      fail "Failed to install ZSH"
      return
    }
    sudo chsh -s /bin/zsh

    local ohmyposh_file=$(mktemp -u)
    curl -fsSL -o "$ohmyposh_file" "https://ohmyposh.dev/install.sh"
    local ohmyposh_code=$?
    if [ $ohmyposh_code -ne 0 ]; then
      warn "Failed to download Oh-my-posh script"
    else
      bash "$ohmyposh_file" -- -d "$XDG_DATA_HOME" || warn "Error occurred while executing Oh-my-posh script"
    fi
    rm -f "$ohmyposh_file"
  }

  install_darwin() {
    brew install --formula jandedobbeleer/oh-my-posh/oh-my-posh || warn "Failed to install Oh-my-posh"
  }

  if [ "$OS" = 'darwin' ]; then
    install_darwin
  elif [ "$OS" = 'linux' ]; then
    install_linux
  fi

  local zinit_file=$(mktemp -u)
  curl -fsSL -o "$zinit_file" "https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh"
  local zinit_code=$?
  if [ $zinit_code -ne 0 ]; then
    warn "Failed to download Zinit script"
  else
    bash "$zinit_file" -- -d "$XDG_DATA_HOME" || warn "Error occurred while executing Zinit script"
  fi
  rm -f "$zinit_file"
}
