GREEN='\033[1;32m'
RED='\033[1;31m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
DEFAULT='\033[0m'

green() {
  if [ $# -ge 2 ]; then
    local label=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    echo -e "$GREEN$label$BLUE ${*:2}$DEFAULT"
  else
    echo -e "$GREEN$1$DEFAULT"
  fi
}

blue() {
  if [ $# -ge 2 ]; then
    local label=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    echo -e "$BLUE$label$BLUE ${*:2}$DEFAULT"
  else
    echo -e "$BLUE$1$DEFAULT"
  fi
}

red() {
  if [ $# -ge 2 ]; then
    local label=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    echo -e "$RED$label$BLUE ${*:2}$DEFAULT"
  else
    echo -e "$RED$1$DEFAULT"
  fi
}

yellow() {
  if [ $# -ge 2 ]; then
    local label=$(echo "$1" | tr '[:lower:]' '[:upper:]')
    echo -e "$YELLOW$label$BLUE ${*:2}$DEFAULT"
  else
    echo -e "$YELLOW$1$DEFAULT"
  fi
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
  echo -e "$message"
}
