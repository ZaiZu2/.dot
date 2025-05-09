is_installed_tmux() {
  command -v tmux >/dev/null 2>&1
}

install_linux() {
  sudo apt install tmux
}

install_darwin() {
  brew install tmux
}

install_tmux() {
  if [ "$OS" = 'darwin' ]; then
    install_linux
  elif [ "$OS" = 'linux' ]; then
    install_darwin
  fi
  git clone "https://github.com/tmux-plugins/tpm" "$XDG_CONFIG_HOME/tmux/plugins/tpm"
  "$XDG_CONFIG_HOME/tmux/plugins/tpm"
  "$XDG_CONFIG_HOME/tmux/plugins/tpm/bin/install_plugins"
}
