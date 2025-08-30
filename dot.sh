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
  local tools=$(list_tools)

  while [[ $# -gt 0 ]]; do
    case $1 in
    setup)
      shift
      local excluded=''
      local only=''
      local force=false
      local skip_pkg_mgr=false

      while [[ $# -gt 0 ]]; do
        case $1 in
        -e | --exclude)
          shift
          while [[ $# -gt 0 && ${1#-} = "$1" ]]; do
            validate_tool_arg "$1" "$tools"
            excluded="$excluded $1"
            shift
          done
          ;;
        -o | --only)
          shift
          while [[ $# -gt 0 && ${1#-} = "$1" ]]; do
            validate_tool_arg "$1" "$tools"
            only="$only $1"
            shift
          done
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

      if [[ $excluded != '' && $excluded != '' ]]; then
        red "-o/--only and -e/--exclude arguments cannot be used together"
        exit
      fi

      open_sudo_session
      load_platform || return $?
      symlink_dotfiles "$force"
      install_font
      [ "$skip_pkg_mgr" = true ] || init_pkg_mgr || return $?
      install_tools "$excluded" "$only" "$force"
      ;;

    install)
      shift
      local excluded=''
      local only=''
      local force=false

      while [[ $# -gt 0 ]]; do
        case $1 in
        -e | --exclude)
          shift
          while [[ $# -gt 0 && ${1#-} = "$1" ]]; do
            validate_tool_arg "$1" "$tools"
            excluded="$excluded $1"
            shift
          done
          ;;
        -o | --only)
          shift
          while [[ $# -gt 0 && ${1#-} = "$1" ]]; do
            validate_tool_arg "$1" "$tools"
            only="$only $1"
            shift
          done
          ;;
        -f | --force)
          force=true
          shift
          ;;
        *)
          multi "$RED" "Unknown option: " "$BLUE" "$1"
          exit 1
          ;;
        esac
      done

      if [[ $excluded != '' && $excluded != '' ]]; then
        red "-o/--only and -e/--exclude arguments cannot be used together"
        exit
      fi

      load_platform || return $?
      open_sudo_session
      install_tools "$excluded" "$only" "$force"
      ;;

    link)
      shift
      local force=false

      while [[ $# -gt 0 ]]; do
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
      done

      blue "Symlinking files"
      symlink_dotfiles "$force"
      ;;

    list)
      blue "Following tools are available:"
      list_tools | tr ' ' '\n'
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

validate_tool_arg(){
  local tools="$2"
  local tool_arg="$1"

  if [[ " $tools " != *" $tool_arg "* ]]; then
    multi "$RED" "Unknown tool: " "$BLUE" "$1"
    exit
  fi
}

entrypoint "$@"
