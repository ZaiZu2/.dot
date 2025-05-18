<<<<<<< Updated upstream
=======
#!/bin/zsh

>>>>>>> Stashed changes
alias df='git --git-dir=$HOME/.git --work-tree=$HOME'
df config --local status.showUntrackedFiles no

autoload -Uz compinit && compinit -u
autoload bashcompinit && bashcompinit

# Add in zsh plugins
source "$XDG_DATA_HOME/zinit/zinit.git/zinit.zsh"
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting
zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions
zinit ice wait lucid
zinit light Aloxaf/fzf-tab
zinit ice wait lucid
zinit snippet OMZP::ssh-agent/ssh-agent.plugin.zsh

zinit light zsh-users/zsh-completions
zinit cdreplay -q # Replay all cached completions

command -v podman > /dev/null && eval "$(podman completion zsh)"
command -v gh > /dev/null && eval "$(gh completion -s zsh)"
command -v fnm > /dev/null && eval "$(fnm completions --shell zsh)"
command -v uv > /dev/null && eval "$(uv generate-shell-completion zsh)"
command -v fnm > /dev/null && eval "$(fnm env --use-on-cd --shell zsh)"
command -v aws > /dev/null && complete -C 'aws_completer' aws

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

bindkey '^p' up-line-or-search
bindkey '^[[A' up-line-or-search # Arrow Up '^[[A'
bindkey '^n' down-line-or-search
bindkey '^[[B' down-line-or-search # Arrow Down '^[[B'

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

setopt globdots # Allow matching hidden files with wildcards
setopt BASH_REMATCH # Turn on BASH_REMATCH[] syntax for capture groups

eval "$(fzf --zsh)"
alias fzf='fzf --preview "bat --theme=kanagawa --color=always --style=numbers --line-range=:500 {}"'

eval "$(oh-my-posh init zsh --config $XDG_CONFIG_HOME/oh-my-posh.toml)"

alias conf='cd $XDG_CONFIG_HOME'
alias nconf='cd $XDG_CONFIG_HOME/nvim'
alias dev='cd $HOME/dev'
alias notes='cd $ZK_NOTEBOOK_DIR'

alias tmux='tmux -f "$XDG_CONFIG_HOME/tmux/tmux.conf"'
alias ls='ls --color'
alias ll='ls -la'
alias gs='git status'
alias gS='git switch'
alias gc='git commit'
alias gp='git pull'
alias gP='git push'
alias gf='git fetch'
alias gl='git log --oneline --decorate --graph'
alias act='source .venv/bin/activate'

[ -f "$HOME/.zsh_absa" ] && source "$HOME/.zsh_absa"
