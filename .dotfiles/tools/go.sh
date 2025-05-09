export GOROOT="$XDG_DATA_HOME/go"

is_installed_go() { command -v go >/dev/null 2>&1; }

build_url() {
  if [ "$ARCH" = 'x86_64' ]; then
    local url_arch='386'
  fi
  echo "https://go.dev/dl/go${GO_VERSION}.${OS}-${url_arch}.tar.gz"
}

install_go() {
  green "Deleting GOROOT dir - $GOROOT"
  sudo rm -rf "$GOROOT"
  green "Downloading V$GO_VERSION from $go_url"
  local go_url="$(build_url)"
  curl -fsSL -o /tmp/go.tar.gz "$go_url" || fail "Failed to download GO binary" || return
  tar -C "$XDG_DATA_HOME" -xzf "/tmp/go.tar.gz"
  green "Extracting to $XDG_DATA_HOME/go"
  rm /tmp/go.tar.gz

  green "Symlinking GO binary"
  ln -sf "$GOROOT/bin/go" "$XDG_BIN_HOME/go"
}
