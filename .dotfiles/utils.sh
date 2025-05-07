error() { echo -e "\033[1;31m[$1]\033[0m ${*:2}"; }
log() { echo -e "\033[1;32m[$1]\033[0m ${*:2}"; }
warn() { echo -e "\033[1;33m[$1]\033[0m ${*:2}"; }

check_fn() {
  for fn in "${@:2}"; do
    if ! declare -f "$fn" >/dev/null; then
      error "$1" "Function '$fn' does not exist"
      return 1
    fi
  done
}
