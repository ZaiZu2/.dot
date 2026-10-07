#!/bin/sh
# Create a fixed set of tmux sessions, each opened on a 3-pane project window.
# Idempotent: sessions (and windows) that already exist are left alone.
#
# Invoked two ways:
#   * From a tmux key binding — always runs, creates any missing sessions.
#   * From a `session-created` hook, passed `--once <session>` — runs only on
#     the first session-created event of the server's lifetime. A server-scope
#     user option (`@sessions-setup-done`) acts as the one-shot marker so that
#     the new-session calls this script itself makes don't re-trigger it.
#     <session> is the session that fired the hook, i.e. the one tmux was
#     started with: if it is a throwaway (default numeric name), its clients
#     are moved to the first of the fixed sessions and it is killed.

set -eu

orig=
if [ "${1-}" = "--once" ]; then
  marker=$(tmux show-options -gv '@sessions-setup-done' 2>/dev/null || true)
  [ "$marker" = "1" ] && exit 0
  tmux set-option -g '@sessions-setup-done' 1
  orig=${2-}
fi

# First of the fixed sessions that exists, in the order below.
first=

setup_session() {
  name="$1"
  path="$2"

  [ -d "$path" ] || return 0
  [ -n "$first" ] || first=$name
  tmux has-session -t "=$name" 2>/dev/null && return 0

  window_name="$(basename "$path")"
  # Target the window by id: a name like ".dot" would be parsed as a pane.
  target=$(tmux new-session -ds "$name" -n "$window_name" -c "$path" -P -F '#{window_id}')

  # Same shape as central_three_panes.sh's 1-pane branch:
  # [left 25%][center 50%][right 25%], focus ends on the center pane.
  tmux split-window -t "$target" -hbd -l 25% -c "$path"
  tmux split-window -t "$target" -h -l 33% -c "$path"
  tmux select-pane -t "$target" -L
}

# Move every client of session $1 to $first, then kill $1.
replace_session() {
  # The hook fires while tmux is still starting: give the client a moment to
  # attach, or it would be left pointing at a dead session.
  tries=0
  while [ -z "$(tmux list-clients -t "=$1" -F '#{client_name}' 2>/dev/null)" ] && [ "$tries" -lt 10 ]; do
    sleep 0.1
    tries=$((tries + 1))
  done
  tmux list-clients -t "=$1" -F '#{client_name}' 2>/dev/null |
    while IFS= read -r client; do
      tmux switch-client -c "$client" -t "=$first"
    done
  tmux kill-session -t "=$1" 2>/dev/null || true
}

setup_session ps       "$HOME/dev/ps-reporting"
setup_session prime    "$HOME/dev/prime_portal"
setup_session fa       "$HOME/dev/fa-absa"
setup_session dotfiles "$HOME/.dot"

# A session named by the user is kept; so is the original one when none of the
# fixed sessions could be created.
case "$orig" in
"" | *[!0-9]*) ;;
*) [ -z "$first" ] || replace_session "$orig" ;;
esac
