export XDG_CONFIG_HOME="$HOME/.config"
export XDG_BIN_HOME="$HOME/.local/bin"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"

PATH="$XDG_BIN_HOME:/bin:/usr/bin:/usr/local/bin:$PATH"
PATH="$GOPATH/bin:$RUSTUP_HOME/bin:$PATH"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# Machine-specific, optional .zshenv
[ -f "$HOME/.zshenv_custom" ] && source "$HOME/.zshenv_custom"
