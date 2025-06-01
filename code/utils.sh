setup_shell() {
  [ $# -eq 0 ] && return 1
  if [ "$1" = 'bash' ]; then
    shopt -s globstar dotglob
  elif [ "$1" = 'zsh' ]; then
    setopt dotglob
  fi
}

check_fn() {
  for fn in "$@"; do
    if ! declare -f "$fn" >/dev/null; then
      red "Function '$fn' does not exist"
      return 1
    fi
  done
}

cap() {
  tr '[:lower:]' '[:upper:]' <<<"$1"
}
