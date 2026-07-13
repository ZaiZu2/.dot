deps_terraform() {
  echo ''
}

is_installed_terraform() {
  command -v terraform >/dev/null 2>&1
}

install_terraform() {
  install_linux() {
    local tf_version
    tf_version=$(curl -fsSL 'https://checkpoint-api.hashicorp.com/v1/check/terraform' |
      grep -oE '"current_version":"[^"]+"' | cut -d'"' -f4) || {
      fail "Failed to resolve latest terraform version"
      return 1
    }
    local tf_arch
    case "$ARCH" in
    x86_64) tf_arch='amd64' ;;
    arm64) tf_arch='arm64' ;;
    esac
    local tf_url="https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_${tf_arch}.zip"
    local tf_zip=$(mktemp)
    blue "Downloading TERRAFORM binary - $tf_url"
    curl -fsSL -o "$tf_zip" "$tf_url" || {
      fail "Failed to download the binary"
      return 1
    }
    blue "Extracting TERRAFORM binary to $XDG_BIN_HOME"
    unzip -o "$tf_zip" terraform -d "$XDG_BIN_HOME" || {
      fail "Failed to extract terraform"
      return 1
    }
    chmod +x "$XDG_BIN_HOME/terraform"
  }

  install_darwin() {
    brew install terraform || {
      fail "Failed to install terraform"
      return 1
    }
  }

  if [ "$OS" = 'darwin' ]; then
    install_darwin || return 1
  elif [ "$OS" = 'linux' ]; then
    install_linux || return 1
  fi
}
