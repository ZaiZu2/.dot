is_installed_dog() {
  command -v dog >/dev/null 2>&1
}

install_linux() {
  echo 'linux'
  sleep 1
  echo 'cat' && warn
  sleep 1
  echo 'bat'
  sleep 1
  echo 'totallywrong' && fail 'shit, it got fucked' && return
  sleep 3
}

install_darwin() {

  echo 'darwin'
  echo 'cat'
  echo 'bat'
}

install_dog() {
  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
  return 1
}
