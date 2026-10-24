#!/bin/bash
# Changes the directory of every pane in the current window that is sitting at a shell prompt. Panes running
# something else (vim, claude, ...) are skipped.
# Usage: cd_all_panes.sh [--popup | <dir>]
#   (none)   the active pane's current path
#   <dir>    that directory
#   --popup  open a minimal zsh (fzf, zoxide) in a popup; its working directory on exit is the target

popup_target() {
  local out zdot
  out=$(mktemp) && zdot=$(mktemp -d) || return 1
  # Throwaway ZDOTDIR with no .zshenv and a minimal .zshrc, so of the real startup files only ~/.zshrc_aliases
  # runs. compinit provides the compdef it calls. PATH comes from the tmux server environment. fzf-tab is sourced
  # from zinit's clone, after fzf, so it owns Tab as in the regular shell.
  cat >"$zdot/.zshrc" <<'EOF'
bindkey -v
PROMPT='%F{yellow}%~%f: '
autoload -Uz compinit && compinit -C
(( $+commands[fzf] )) && eval "$(fzf --zsh)" && bindkey '^E' fzf-cd-widget
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
fzf_tab=${XDG_DATA_HOME:-$HOME/.local/share}/zinit/plugins/Aloxaf---fzf-tab/fzf-tab.plugin.zsh
[[ -r $fzf_tab ]] && source $fzf_tab
source "$HOME/.zshrc_aliases"
zshexit() { print -r -- $PWD >| $CD_ALL_PANES_OUT }
q() { CD_ALL_PANES_OUT=/dev/null; exit }
EOF
  tmux display-popup -E -w 70 -h 14 -d '#{pane_current_path}' \
    -T ' cd all panes (exit to apply, q to abort) ' \
    "ZDOTDIR=$(printf '%q' "$zdot") CD_ALL_PANES_OUT=$(printf '%q' "$out") zsh -i"
  cat "$out"
  rm -rf "$out" "$zdot"
}

if [ "$1" = "--popup" ]; then
  target=$(popup_target)
  [ -z "$target" ] && exit 0
else
  target=${1:-$(tmux display-message -p '#{pane_current_path}')}
  target=${target/#\~/$HOME}
fi

[ -d "$target" ] || exit 1

panes=()
while read -r pane cmd; do
  case "$cmd" in
    zsh | bash | sh | fish) panes+=("$pane") ;;
  esac
done < <(tmux list-panes -F '#{pane_id} #{pane_current_command}')

# C-c first discards whatever is typed at the prompt, in any shell and vi mode, so the cd is not appended to it.
# The shell flushes pending input on the interrupt, so the cd is sent only after it has settled.
for pane in "${panes[@]}"; do tmux send-keys -t "$pane" C-c; done
sleep 0.1
for pane in "${panes[@]}"; do
  tmux send-keys -t "$pane" "cd -- $(printf '%q' "$target") && clear" Enter
done
