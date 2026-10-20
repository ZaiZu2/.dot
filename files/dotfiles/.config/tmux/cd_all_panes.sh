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
  # Throwaway ZDOTDIR with no .zshenv and a minimal .zshrc, so none of the real startup files run. PATH comes
  # from the tmux server environment.
  cat >"$zdot/.zshrc" <<'EOF'
bindkey -v
PROMPT='%F{yellow}%~%f: '
(( $+commands[fzf] )) && eval "$(fzf --zsh)" && bindkey '^E' fzf-cd-widget
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
  _cdap_zi() { local d=$(zoxide query --interactive) && [[ -n $d ]] && { BUFFER="cd ${(q)d}"; zle accept-line } }
  zle -N _cdap_zi
  bindkey '^G' _cdap_zi
fi
alias ...='cd ../..' ....='cd ../../..' .....='cd ../../../..'
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

while read -r pane cmd; do
  case "$cmd" in
    zsh | bash | sh | fish) tmux send-keys -t "$pane" "cd -- $(printf '%q' "$target") && clear" Enter ;;
  esac
done < <(tmux list-panes -F '#{pane_id} #{pane_current_command}')
