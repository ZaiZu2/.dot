is_installed_git() { command -v git >/dev/null 2>&1; }

install_git() {
  if [ "$OS" = 'darwin' ]; then
    brew install git || return $?
  elif [ "$OS" = 'linux' ]; then
    sudo apt install --yes git || return $?
  fi
}
