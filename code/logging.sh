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

print_help() {
  cat <<-EOF
		Tool automating the process of setting up a development environment.

		Usage: dot [command] [options]
		
		Commands:
		  link [-f|--force]
		      Create symlinks for dotfiles.
		      Options:
		        -f, --force    Overwrite existing files or symlinks.
		
		  setup [-e|--exclude <tools>] [-o|--only <tools>] [-f|--force] [-s|--skip-pkg-mgr]
		      Set up environment: symlink dotfiles, install fonts, packages, and tools.
		      Options:
		        -e, --exclude <tools>     Exclude specific tools from installation. Expects space-separated list.
		        -o, --only <tools>        Install only specified tools. Expects space-separated list.
		        -f, --force               Force file overwrite during symlink and setup.
		        -s, --skip-pkg-mgr        Skip system package manager setup.
		
		  list
		      List currently available tools.

		  export [patch-file]
		      Export local commits as a patch zip file. Defaults to 'patch.zip' if no file specified.
		      Useful when the machine cannot push to origin.

		  import [patch-file]
		      Import and apply patches from a zip file. Defaults to 'patch.zip' if no file specified.

		  create <tool-name>
		      Create shell files for a new tool using a template.

		  --help
		      Show this help message and exit.
		EOF
}
