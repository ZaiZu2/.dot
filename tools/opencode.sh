deps_opencode() {
  echo ''
}

is_installed_opencode() { command -v cargo >/dev/null 2>&1; }

install_opencode() {
  local script_file=$(mktemp -u)
  blue "Downloading install script"
  curl -fsSL -o "$script_file" https://opencode.ai/install || {
    fail "Failed to download the script"
    return
  }
  blue "Running install script"
  bash "$script_file" -y --no-modify-path || {
    fail "Error occurred while executing the script"
    return
  }
  rm -f "$script_file"
}
