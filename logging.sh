GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
DEFAULT='\033[0m'

green() {
  echo -e "$GREEN$1$DEFAULT"
}

blue() {
  echo -e "$BLUE$1$DEFAULT"
}

red() {
  echo -e "$RED$1$DEFAULT"
}

yellow() {
  echo -e "$YELLOW$1$DEFAULT"
}

multi() {
  [ $(($# % 2)) -eq 1 ] && {
    red "'multi' function accepts only even number of arguments, $# were passed"
    return 1
  }

  local message=''
  while [ ! $# -eq 0 ]; do
    local color="$1"
    local text="$2"
    message="$message$color$text"
    shift 2
  done
  echo -e "$message$DEFAULT"
}
