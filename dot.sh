#!/bin/bash

get_shell() {
  if [ -n "$BASH_VERSION" ]; then
    echo bash
  elif [ -n "$ZSH_VERSION" ]; then
    echo zsh
  else
    red "Program only supports Zsh and Bash"
    return 1
  fi
}

get_script_dir() {
  [ $# -eq 0 ] && return 1
  if [ "$1" = 'bash' ]; then
    dirname "$(realpath "${BASH_SOURCE[0]}")"
  elif [ "$1" = 'zsh' ]; then
    dirname "$(realpath "${(%):-%x}"))"
  fi
}

USED_SHELL="$(get_shell || return $?)"
SCRIPT_DIR="$(get_script_dir "$USED_SHELL" || return $?)"
source "$SCRIPT_DIR/code/constants.sh"
source "$SCRIPT_DIR/code/utils.sh"
source "$SCRIPT_DIR/code/logging.sh"
source "$SCRIPT_DIR/code/commands.sh"
source "$SCRIPT_DIR/code/tool.sh"

entrypoint() {
  if [[ $# -eq 0 || $1 = '--help' || $1 = '-h' ]]; then
    print_help
    return 1
  fi

  setup_shell "$USED_SHELL" || return $?

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
        multi "$RED" "Unknown option: " "$BLUE" "$1"
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
          multi "$RED" "Unknown option: " "$BLUE" "$1"
          exit 1
          ;;
        esac
      done

      load_platform || return $?
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
      multi "$RED" "Unknown option: " "$BLUE" "$1"
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
  source "$SCRIPT_DIR/code/$OS.sh"
}

open_sudo_session() {
  # Invalidate any cached credentials if they are incorrect
  if sudo --non-interactive true 2>/dev/null; then
    sudo --remove-timestamp
    blue "Provide admin credentials"
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

entrypoint "$@"
