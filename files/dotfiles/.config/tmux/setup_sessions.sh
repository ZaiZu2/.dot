#!/bin/sh
# Create a fixed set of tmux sessions, each opened on a 3-pane project window.
# Idempotent: sessions (and windows) that already exist are left alone.
#
# Invoked two ways:
#   * From a tmux key binding — always runs, creates any missing sessions.
#   * From a `session-created` hook, passed `--once` — runs only on the first
#     session-created event of the server's lifetime. A server-scope user
#     option (`@sessions-setup-done`) acts as the one-shot marker so that the
#     new-session calls this script itself makes don't re-trigger it.

set -eu

if [ "${1-}" = "--once" ]; then
  marker=$(tmux show-options -gv '@sessions-setup-done' 2>/dev/null || true)
  [ "$marker" = "1" ] && exit 0
  tmux set-option -g '@sessions-setup-done' 1
fi

setup_session() {
  name="$1"
  path="$2"

  [ -d "$path" ] || return 0
  tmux has-session -t "=$name" 2>/dev/null && return 0

  window_name="$(basename "$path")"
  tmux new-session -ds "$name" -n "$window_name" -c "$path"

  target="$name:$window_name"

  # Same shape as central_three_panes.sh's 1-pane branch:
  # [left 25%][center 50%][right 25%], focus ends on the center pane.
  tmux split-window -t "$target" -hbd -l 25% -c "$path"
  tmux split-window -t "$target" -h -l 33% -c "$path"
  tmux select-pane -t "$target" -L
}

setup_session ps       "$HOME/dev/ps-reporting"
setup_session prime    "$HOME/dev/prime_portal"
setup_session fa       "$HOME/dev/fa-absa"
setup_session dotfiles "$HOME/.dot"
