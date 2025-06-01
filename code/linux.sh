init_pkg_mgr() {
  blue "Updating system packages information"
  sudo apt update || return 1
  blue "Installing/upgrading system packages"
  sudo apt upgrade --yes || return 1
  sudo apt install --yes cmake curl pkg-config libtool unzip ripgrep jq \
    build-essential libreadline-dev coreutils || return 1
  blue "Removing redundant packages"
  sudo apt autoremove --yes || return 1
}

install_font() {
  blue "Copying fonts"
  sudo cp "$SCRIPT_DIR/files/font/"* '/usr/share/fonts'
  sudo chmod 0644 '/usr/share/fonts/'*
}
