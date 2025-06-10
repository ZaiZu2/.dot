deps_fnm() {
  echo ''
}

is_installed_fnm() {
  command -v fnm >/dev/null 2>&1
}

install_fnm() {
  blue "Downloading FNM script"
  fnm_file=$(mktemp)
  curl -fsSL -o "$fnm_file" "https://fnm.vercel.app/install" || {
    fail "Failed to download the script"
    return 1
  }
  blue "Executing FNM script"
  bash "$fnm_file" --skip-shell || {
    multi "$RED" "Error occured while executing " "$BLUE" "FNM" "$RED" " script"
    return 1
  }
  blue "Install latest Node.js"
  fnm install --lts || {
    warn 'Failed to install latest Node.js'
    return 1
  }
}
