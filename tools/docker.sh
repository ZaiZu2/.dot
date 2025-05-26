is_installed_docker() {
  command -v docker >/dev/null 2>&1
}

install_linux() {
  blue "Downloading DOCKER script"
  sudo mkdir -p '/etc/apt/keyrings'
  gpg_key=$(mktemp)
  curl -fsSL -o "$gpg_key" 'https://download.docker.com/linux/ubuntu/gpg' || {
    multi "$RED" "Failed to download " "$BLUE" "DOCKER" "$RED" " gpg key"
    return 1
  }
  sudo cat "$gpg_key" | tee '/etc/apt/keyrings/docker.gpg' >/dev/null

  blue "Adding DOCKER repository"
  dpkg_architecture=$(dpkg --print-architecture)
  echo "deb [arch=${dpkg_architecture} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs 2>/dev/null) stable" |
    sudo tee '/etc/apt/sources.list.d/docker.list'
  sudo chmod 0644 '/etc/apt/sources.list.d/docker.list' # Set correct permissions

  blue "Installing DOCKER packages"
  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
    multi "$RED" "Failed to install " "$BLUE" "DOCKER" "$RED" " packages"
    return 1
  }

  blue "Setting DOCKER as a linux service"
  sudo systemctl enable --now docker
  blue "Adding current user to the DOCKER group"
  sudo usermod -aG docker "$USER"
}

install_darwin() {
  brew install docker || {
    fail "Failed to install docker"
    return 1
  }
}

install_docker() {
  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
