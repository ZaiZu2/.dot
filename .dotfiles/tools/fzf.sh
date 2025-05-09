_install_linux() {
  fzf_repo="$XDG_DATA_HOME/fzf"
  if [ ! -d "$fzf_repo" ]; then
    git -C "$fzf_repo" pull || return 1
  else
    git clone --depth 1 "https://github.com/junegunn/fzf.git" "$fzf_repo" || return 1
  fi
  bash "$fzf_repo/install" --bin --no-update-rc --no-fish || return 1
  ln -sf "$fzf_repo/bin/fzf" "$XDG_BIN_HOME/fzf" || return 1

}

is_installed_fzf() {
  command -v fzf >/dev/null 2>&1
}

install_fzf() {
  if [ "$OS" = 'darwin' ]; then
    brew install fzf || return $?
  elif [ "$OS" = 'linux' ]; then
    _install_linux || return $?
  fi

}
