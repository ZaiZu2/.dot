deps_claude() {
  echo ''
}

is_installed_claude() {
  command -v claude >/dev/null 2>&1
}

install_claude() {
  local script_file=$(mktemp -u)
  blue "Downloading install script"
  curl -fsSL -o "$script_file" https://claude.ai/install.sh || {
    fail "Failed to download the script"
    return 1
  }
  blue "Running install script"
  bash "$script_file" || {
    fail "Error occurred while executing the script"
    return 1
  }
  rm -f "$script_file"
}
