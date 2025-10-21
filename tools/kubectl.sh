deps_kubectl() {
  echo ''
}

is_installed_kubectl() {
  command -v kubectl >/dev/null 2>&1
}

install_kubectl() {
  install_linux() {
    local kubectl_url="https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$ARCH/kubectl"
    local kubectl_file=$(mktemp)
    blue "Downloading KUBECTL binary - $kubectl_url"
    curl -fsSL -o "$kubectl_file" "$kubectl_url" || {
      fail "Failed to download the binary"
      return 1
    }
    blue "Moving KUBECTL script to $XDG_BIN_HOME"
    mv "$kubectl_file" "$XDG_BIN_HOME/kubectl"
    chmod +x "$XDG_BIN_HOME/kubectl"
  }

  install_darwin() {
    brew install kubectl || {
      fail "Failed to install kubectl"
      return 1
    }
  }

  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
