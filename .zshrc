export PATH="/bin:/usr/bin:/usr/local/bin:$HOME/bin:$HOME/.local/bin:$PATH"
export PATH="/opt/nvim-linux64/bin:$PATH"

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

export PATH="$HOME/.fzf/bin:$PATH"
source "/home/jakub/.fzf/shell/completion.zsh"
source "/home/jakub/.fzf/shell/key-bindings.zsh"
FZF_DEFAULT_OPTS='--height 40% --border'

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Alias for saving changes to backup .dotfiles repo
alias df='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
df config --local status.showUntrackedFiles no

# # Start SSH agent and load all keys (mainly for Git)
# env=~/.ssh/agent.env
#
# agent_load_env () { [[ -f "$env" ]] && . "$env" >| /dev/null }
#
# agent_start () {
#     (umask 077; ssh-agent >| "$env")
#     . "$env" >| /dev/null
# }
#
# agent_load_env
#
# # agent_run_state: 0=agent running w/ key; 1=agent w/o key; 2=agent not running
# agent_run_state=$(ssh-add -l >| /dev/null 2>&1; echo $?)
#
# if [[ ! "$SSH_AUTH_SOCK" || $agent_run_state = 2 ]]; then
#     agent_start
#     ssh-add
# elif [[ "$SSH_AUTH_SOCK" && $agent_run_state = 1 ]]; then
#     ssh-add
# fi
#
# unset env

eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/conf.toml)"

# Add in zsh plugins
# zinit light zsh-users/zsh-syntax-highlighing
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# VIM support
zinit light softmoth/zsh-vim-mode
MODE_CURSOR_VIINS="white blinking bar"
MODE_CURSOR_REPLACE="$MODE_CURSOR_VIINS #ff0000"
MODE_CURSOR_VICMD="white block"
MODE_CURSOR_SEARCH="#ff00ff steady underline"
MODE_CURSOR_VISUAL="$MODE_CURSOR_VICMD steady bar"
MODE_CURSOR_VLINE="$MODE_CURSOR_VISUAL #00ffff"
bindkey -v
export KEYTIMEOUT=1
alias vim='nvim'

# Load completions
autoload -U compinit && compinit

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

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

alias ls='ls --color'

# Shell integrations
# eval "$(fzf --zsh)"
# eval "$(zoxide init --cmd cd zsh)"

# TODO: Add VIM mod to zsh

