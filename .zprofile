export XDG_CONFIG_HOME="$HOME/.config"
export XDG_BIN_HOME="$HOME/.local/bin"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

export PATH="$XDG_BIN_HOME:/bin:/usr/bin:/usr/local/bin:$PATH"
export PATH="/usr/local/go:$XDG_DATA_HOME/cargo/bin:$PATH"

export EDITOR=nvim
