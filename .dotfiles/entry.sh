#!/bin/bash

get_shell() {
  if [ -n "$BASH_VERSION" ]; then
    echo bash
  elif [ -n "$ZSH_VERSION" ]; then
    echo zsh
  else
    red "Could not recognize shell"
    exit 1
  fi
}

get_script_dir() {
  shell="$(get_shell)"
  if [ "$shell" = 'bash' ]; then
    dirname "$(realpath "${BASH_SOURCE[0]}")"
  elif [ "$shell" = 'zsh' ]; then
    dirname "$(realpath "${(%):-%x}"))"
  fi
}
SCRIPT_DIR="$(get_script_dir)"

source "utils.sh"
source "constants.sh"
source "tool.sh"

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -e | --exclude)
      EXCLUDED=$2
      shift 2
      ;;
    -o | --only)
      ONLY=$2
      shift 2
      ;;
    -f | --force)
      FORCE='true'
      shift
      ;;
    -s | --skip-pkg-mgr)
      SKIP_PKG_MGR='true'
      shift
      ;;
    *)
      red "Unknown option: $1"
      local did_error=true
      shift
      ;;
    esac
  done
  if [[ "${did_error:-}" == true ]]; then
    return 1
  fi
}

load_platform() {
  OS="$(uname --kernel-name | tr '[:upper:]' '[:lower:]')" || return 1

  case "$OS" in
  linux | darwin) ;;
  *)
    red "Platform unsupported: $OS"
    exit 1
    ;;
  esac

  ARCH="$(uname --machine | tr '[:upper:]' '[:lower:]')" || return 1
  case "$ARCH" in
  x86_64 | arm64) ;;
  *)
    red "Architecture unsupported: $ARCH"
    exit 1
    ;;
  esac

  blue "Platform recognized as $OS-$ARCH"
  source "$SCRIPT_DIR/$OS.sh"
}

open_sudo_session() {
  # Invalidate any cached credentials if they are incorrect
  if sudo --non-interactive true 2>/dev/null; then
    sudo --remove-timestamp
    blue "Provide admin credentials:"
  fi

  if ! sudo --validate; then
    red "This script requires admin rights"
    exit 1
  fi

  (while true; do
    sudo -n true
    sleep 60
  done) &
  SUDO_SESSION_PID=$!
  trap 'kill "$SUDO_SESSION_PID" 2>/dev/null' EXIT HUP INT QUIT TERM
}

symlink_dotfiles() {
  ls "$SCRIPT_DIR/files/dotfiles/"
  for dotfile in "$SCRIPT_DIR/files/dotfiles/."*; do
    ln -sf "$dotfile" "$HOME/$(basename "$dotfile")"
  done
  blue "Symlinked dotfiles"
}

main() {
  parse_args "$@" || return $?
  load_platform || return $?

  symlink_dotfiles
  open_sudo_session
  install_font
  [ "$SKIP_PKG_MGR" = 'true' ] || init_pkg_mgr || return $?
  install_tools
}

main "$@"
