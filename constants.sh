source "utils.sh"

XDG_CONFIG_HOME="$HOME/.config"
XDG_BIN_HOME="$HOME/.local/bin"
XDG_DATA_HOME="$HOME/.local/share"
XDG_CACHE_HOME="$HOME/.cache"

USED_SHELL="$(get_shell)"
SCRIPT_DIR="$(get_script_dir)"
LOGS_DIR="$SCRIPT_DIR/logs"
DOTFILES_DIR="$SCRIPT_DIR/files/dotfiles"

GO_VERSION="1.23.3"
