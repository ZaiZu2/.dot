export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

is_installed_rust() { command -v cargo >/dev/null 2>&1; }

install_rust() {
  curl https://sh.rustup.rs -Sf | sh -s -- -y --no-modify-path
  rustup override set stable || return 1
  rustup update stable || return 1

  for file in "$CARGO_HOME/bin/"*; do
    ln -sf "$file" "$XDG_BIN_HOME/$(basename "$file")"
  done
}
