#!/bin/sh
# Create a 3-pane project window (utility | code | claude) in a given directory.
# Usage: new_project_window.sh [-s SESSION] <path>

set -eu

usage() {
  echo "Usage: $(basename "$0") [-s SESSION] <path>" >&2
  exit 1
}

target_session=""
while getopts "s:h" opt; do
  case "$opt" in
    s) target_session="$OPTARG" ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

[ $# -eq 1 ] || usage

project_path="$(realpath "$1")"
[ -d "$project_path" ] || { echo "Not a directory: $project_path" >&2; exit 1; }
window_name="$(basename "$project_path")"

if [ -n "$target_session" ]; then
  if ! tmux has-session -t "=$target_session" 2>/dev/null; then
    tmux new-session -ds "$target_session" -c "$project_path"
  fi
  session="$target_session"
else
  session="$(tmux display-message -p '#S')"
fi

tmux new-window -t "$session:" -n "$window_name" -c "$project_path"
target="$session:$window_name"

# central_three_panes.sh acts on the current client's active pane, so make
# the new window active first (works whether target session is current or not).
tmux switch-client -t "$session"
tmux select-window -t "$target"

"$XDG_CONFIG_HOME/tmux/central_three_panes.sh"

# After central_three_panes.sh (from a 1-pane start): focus is on the right
# pane, layout is [left 25%][center 50%][right 25%].
tmux send-keys -t "$target" 'claude' C-m
tmux select-pane -t "$target" -L
