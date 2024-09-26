
export PATH="/bin:/usr/bin:/usr/local/bin:$HOME/bin:$HOME/.local/bin:$PATH"

# Install Zsh plugin manager - Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

alias tmux="tmux -f ~/.config/tmux/tmux.conf"
alias ls='ls --color'
alias df='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
df config --local status.showUntrackedFiles no

eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/conf.toml)"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit snippet OMZP::ssh-agent/ssh-agent.plugin.zsh

zinit light zsh-users/zsh-completions
autoload -U compinit
compinit -C
zinit cdreplay -q # Replay all cached completions

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

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# Node.js manager
eval "$(fnm completions --shell zsh)"
eval "$(fnm env --use-on-cd --shell zsh)"

if [[ "$(uname)" == "Darwin" ]]; then
  # macOS
else
  # Linux
export PATH="/opt/nvim-linux64/bin:$PATH"
  export PATH="$HOME/.fmt:$PATH"
fi

for file in ~/zsh/.fzf.sh; do
    source "$file";
done
unset file;

# zprof
