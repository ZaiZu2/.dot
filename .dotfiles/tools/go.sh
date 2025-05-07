export GOROOT="$XDG_DATA_HOME/go"

is_installed_go() { command -v go >/dev/null 2>&1; }

install_go() {
  rm -rf "$GOROOT"

  curl -Sf -o /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.darwin-arm64.tar.gz" || return 1
  tar -C "$XDG_DATA_HOME" -xzf "/tmp/go.tar.gz"
  rm /tmp/go.tar.gz

  ln -sf "$GOROOT/bin/go" "$XDG_BIN_HOME/go"

  return 1

}
