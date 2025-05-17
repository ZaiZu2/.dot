export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

is_installed_rust() { command -v cargo >/dev/null 2>&1; }

install_rust() {
  local script_file=$(mktemp -u)
  blue "Downloading install script"
  curl -fsSL -o "$script_file" https://sh.rustup.rs || {
    fail "Failed to download the script"
    return
  }
  blue "Running install script"
  bash "$script_file" -y --no-modify-path || {
    fail "Error occured while executing the script"
    return
  }
  rm -f "$script_file"
  blue "Symlinking binaries"
  for file in "$CARGO_HOME/bin/"*; do
    ln -sf "$file" "$XDG_BIN_HOME/$(basename "$file")"
  done
}
