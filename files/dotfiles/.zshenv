#!/bin/zsh

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_BIN_HOME="$HOME/.local/bin"
PATH="$XDG_BIN_HOME:/bin:/usr/bin:/usr/local/bin:$PATH"

export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
. "$CARGO_HOME/env"

export GOROOT="$XDG_DATA_HOME/go"

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

setopt nullglob # Temporarily make glob pattern expand to nothing
for dotfile in "$HOME/.zshenv_"*; do
    source $dotfile
done
unsetopt nullglob
