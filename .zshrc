export XDG_CONFIG_HOME="$HOME/.config"
export XDG_BIN_HOME="$HOME/.local/bin"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export PATH="/bin:/usr/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

alias tmux="tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf"
alias ls='ls --color'
alias df='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
df config --local status.showUntrackedFiles no

source "$XDG_DATA_HOME/zinit/zinit.git/zinit.zsh"
eval "$(oh-my-posh init zsh --config $XDG_CONFIG_HOME/ohmyposh/conf.toml)"
source <(fzf --zsh)
eval "$(fnm env --use-on-cd --shell zsh)"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit snippet OMZP::ssh-agent/ssh-agent.plugin.zsh

autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit
zinit light zsh-users/zsh-completions
zinit cdreplay -q # Replay all cached completions
source <(podman completion zsh)
source <(gh completion -s zsh) # GitHub completions
eval "$(fnm completions --shell zsh)"
eval "$(uv generate-shell-completion zsh)"
complete -C 'aws_completer' aws

# VIM support
zinit light softmoth/zsh-vim-mode
MODE_CURSOR_VIINS="#C8C093 blinking bar"
MODE_CURSOR_REPLACE="$MODE_CURSOR_VIINS #ff0000"
MODE_CURSOR_VICMD="#C8C093 block"
MODE_CURSOR_SEARCH="#ff00ff steady underline"
MODE_CURSOR_VISUAL="$MODE_CURSOR_VICMD steady bar"
MODE_CURSOR_VLINE="$MODE_CURSOR_VISUAL #00ffff"
bindkey -v
export KEYTIMEOUT=1

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# bindkey '^p' history-search-backward
# bindkey '^n' history-search-forward
# bindkey '^p' up-line-or-search
# bindkey '^n' down-line-or-search

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

setopt globdots # Allow matching hidden files with wildcards
