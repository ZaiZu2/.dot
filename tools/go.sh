export GOROOT="$XDG_DATA_HOME/go"

deps_go() {
  echo ''
}

is_installed_go() { command -v go >/dev/null 2>&1; }

install_go() {
  build_url() {
    if [ "$ARCH" = 'x86_64' ]; then
      local url_arch='386'
    else
      local url_arch="$ARCH"
    fi
    # echo $url_arch
    echo "https://go.dev/dl/go${GO_VERSION}.${OS}-${url_arch}.tar.gz"
  }

  blue "Deleting GOROOT dir - $GOROOT"
  sudo rm -rf "$GOROOT"
  local go_url="$(build_url)"
  blue "Downloading V$GO_VERSION from $go_url"
  curl -fsSL -o /tmp/go.tar.gz "$go_url" || {
    fail "Failed to download GO binary"
    return 1
  }
  tar -C "$XDG_DATA_HOME" -xzf "/tmp/go.tar.gz"
  blue "Extracting to $XDG_DATA_HOME/go"
  rm /tmp/go.tar.gz

  blue "Symlinking GO binary"
  ln -sf "$GOROOT/bin/go" "$XDG_BIN_HOME/go"
}
