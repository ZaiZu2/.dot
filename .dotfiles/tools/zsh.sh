is_installed_zsh() {
  command -v zsh >/dev/null 2>&1
}

install_linux() {
  brew install zsh
  chsh -s /bin/zsh
  curl -fsSL "https://ohmyposh.dev/install.sh" | bash -s -- -d "$XDG_DATA_HOME"
  curl -fsSL "https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh" | bash -s
}

install_darwin() {
  brew install zsh
  chsh -s /bin/zsh
  brew install jandedobbeleer/oh-my-posh/oh-my-posh
  curl -fsSL "https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh" | bash -s
}

install_zsh() {
  if [ "$OS" = 'darwin' ]; then
    install_darwin
  elif [ "$OS" = 'linux' ]; then
    install_linux
  fi
}
