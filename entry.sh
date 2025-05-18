#!/bin/bash

source "logging.sh"
source "utils.sh"
source "constants.sh"
source "tool.sh"

entrypoint() {
  setup_shell
  load_platform || return $?

  while [[ $# -gt 0 ]]; do
    case $1 in
    symlink)
      shift
      local force=false

      case $1 in
      -f | --force)
        local force=true
        shift
        ;;
      *)
        red "Unknown option: $1"
        exit 1
        ;;
      esac

      blue "Symlinking files"
      symlink_dotfiles "$force"
      ;;

    setup)
      shift
      local excluded=''
      local only=''
      local force=false
      local skip_pkg_mgr=false

      while [[ $# -gt 0 ]]; do
        case $1 in
        -e | --exclude)
          local excluded=$2
          shift 2
          ;;
        -o | --only)
          local only=$2
          shift 2
          ;;
        -f | --force)
          local force=true
          shift
          ;;
        -s | --skip-pkg-mgr)
          local skip_pkg_mgr=true
          shift
          ;;
        *)
          red "Unknown option: $1"
          exit 1
          ;;
        esac
      done

      setup "$excluded" "$only" "$force" "$skip_pkg_mgr"
      ;;

    list)
      blue "Following tools are available:"
      for file in "$SCRIPT_DIR/tools/"*; do
        basename -s '.sh' "$file"
      done
      exit
      ;;

    create)
      shift
      if [ ! $# -eq 1 ]; then
        red "Provide the name of a tool as a single parameter"
        exit 1
      fi
      create_tool_template "$1"
      exit
      ;;

    *)
      red "Unknown option: $1"
      exit 1
      ;;
    esac
  done
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
  local force=${1-false}

  for dotfile in "$DOTFILES_DIR"/**/*; do
    [ -d "$dotfile" ] && continue

    local rel_path=${dotfile##"$DOTFILES_DIR/"}
    target_path="$HOME/$rel_path"
    if [[ -f "$target_path" && "$force" = false ]]; then
      multi "$YELLOW" "Skipping " "$BLUE" "$target_path" "$YELLOW" ", file already exists"
    elif [[ -L "$target_path" && "$force" = false ]]; then
      multi "$YELLOW" "Skipping " "$BLUE" "$target_path" "$YELLOW" ", symlink already exists"
    else
      ln -s "$dotfile" "$target_path"
    fi
  done
}

setup() {
  local excluded="${1-}"
  local only="${2-}"
  local force="${3-false}"
  local skip_pkg_mgr="${4-false}"

  symlink_dotfiles "$force"
  open_sudo_session
  install_font
  [ "$skip_pkg_mgr" = true ] || init_pkg_mgr || return $?
  install_tools "$excluded" "$only" "$force"
}

entrypoint "$@"
