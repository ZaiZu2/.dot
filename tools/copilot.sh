deps_copilot() {
  echo ''
}

is_installed_copilot() {
  command -v copilot >/dev/null 2>&1
}

install_copilot() {
  local script_file=$(mktemp -u)
  blue "Downloading install script"
  curl -fsSL -o "$script_file" https://gh.io/copilot-install || {
    fail "Failed to download the script"
    return 1
  }
  blue "Running install script"
  # Pin the prefix so the binary lands in ~/.local/bin, already on PATH via .zshenv
  PREFIX="$HOME/.local" bash "$script_file" || {
    fail "Error occurred while executing the script"
    return 1
  }
  rm -f "$script_file"
}
