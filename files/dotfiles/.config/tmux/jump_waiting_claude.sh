#!/bin/sh
# Jump to a Claude pane; press again to cycle to the next one.
# Bound to `prefix C-c` in tmux.conf.
#
# Cycle order: waiting panes first (oldest marker first), then any other
# live Claude pane. Wraps around. If no Claude pane exists anywhere,
# spawns a new one in the current window.

set -eu

WAIT_DIR="${TMPDIR:-/tmp}/claude-waiting"

jump_to_pane() {
  # $1 = pane_id like "%42". Switches session, window, and pane.
  target=$(tmux display-message -t "$1" -p '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null) || return 1
  session=${target%%:*}
  window=${target%.*}
  tmux switch-client -t "$session" 2>/dev/null || true
  tmux select-window -t "$window" 2>/dev/null || true
  tmux select-pane -t "$1" 2>/dev/null || true
  return 0
}

# Current pane — used to decide "cycle to next" vs "jump to first".
current=$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)

# Waiting markers, oldest first. Prune dead ones inline.
waiting=""
if [ -d "$WAIT_DIR" ]; then
  # -tr = mtime ascending (oldest first)
  for marker in $(ls -tr "$WAIT_DIR" 2>/dev/null); do
    pane_id="%$marker"
    if tmux display-message -t "$pane_id" -p '#{pane_id}' >/dev/null 2>&1; then
      waiting="$waiting$pane_id
"
    else
      rm -f "$WAIT_DIR/$marker" 2>/dev/null || true
    fi
  done
fi

# All live Claude panes.
all_claude=$(tmux list-panes -a -F '#{pane_id} #{pane_current_command}' 2>/dev/null |
  awk '$2 ~ /^claude(\.exe)?$/ {print $1}')

# Merge: waiting first, then remaining claude panes not already in `waiting`.
# awk dedupes while preserving order.
ordered=$(printf '%s\n%s\n' "$waiting" "$all_claude" |
  awk 'NF && !seen[$0]++')

if [ -z "$ordered" ]; then
  # No Claude anywhere — spawn one in the current window.
  tmux split-window -h "zsh -ic c"
  exit 0
fi

first=$(printf '%s\n' "$ordered" | head -n1)
next=$(printf '%s\n' "$ordered" | awk -v c="$current" '
  prev==c { print; exit }
  { prev=$0 }
')
jump_to_pane "${next:-$first}"
