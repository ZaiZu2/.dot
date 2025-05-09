init_pkg_mgr() {
  sudo apt update || return 1
  blue "Updated system packages information"
  sudo apt upgrade --yes || return 1
  sudo apt install --yes cmake curl pkg-config libtool unzip ripgrep \
    build-essential libreadline-dev coreutils || return 1
  blue "Upgraded all system packages"
  sudo apt autoremove --yes || return 1
  blue "Removed all redundant packages"
}

install_font() {
  sudo cp "$SCRIPT_DIR/files/font/"* /usr/share/fonts
  sudo chmod 644 /usr/share/fonts/*
  blue "Installed fonts"
}
