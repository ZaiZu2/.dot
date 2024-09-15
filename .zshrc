export PATH="/bin:/usr/bin:/usr/local/bin:$HOME/bin:$HOME/.local/bin:$PATH"
export PATH="/opt/nvim-linux64/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Download Zinit, if it's not there yet
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Alias for saving changes to backup .dotfiles repo
alias df='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
df config --local status.showUntrackedFiles no

eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/conf.toml)"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Load completions
zinit light zsh-users/zsh-completions
autoload -U compinit && compinit
zinit cdreplay -q # Replay all cached completions

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

alias ls='ls --color'

if [[ ! "$PATH" == */home/jakub/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/jakub/.fzf/bin"
fi
source <(fzf --zsh)
source "/home/jakub/.fzf/shell/completion.zsh"
source "/home/jakub/.fzf/shell/key-bindings.zsh"
FZF_DEFAULT_OPTS='--height 40% --border'

for file in ~/zsh/.ssh.sh; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done
unset file;

