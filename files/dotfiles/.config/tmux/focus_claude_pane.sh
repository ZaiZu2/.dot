#!/bin/sh

if [ -z "$TMUX" ]; then
  echo "Not in a tmux session"
  exit 1
fi

# Iterate through panes in reverse, looking for an idle pane
for pane_info in $( \
  tmux list-panes -F "#{pane_id}:#{pane_pid}:#{pane_current_command}" \
  | awk '{a[NR]=$0} END{for(i=NR;i>=1;i--)print a[i]}' \
); do
  PANE_ID=$(echo "$pane_info" | cut -d : -f1)
  PANE_PID=$(echo "$pane_info" | cut -d : -f2)
  PANE_CMD=$(echo "$pane_info" | cut -d : -f3)
  CLAUDE_PID=$(pgrep -P "$PANE_PID" claude)

  # CLAUDE pane exists, focus it
  if [ -n "$CLAUDE_PID" ]; then
    tmux select-pane -t "$PANE_ID"
    exit
  fi
  # Idle pane exists
  if [ -n "$PANE_CMD" ] && ! pgrep -P "$PANE_PID" >/dev/null 2>&1; then
    tmux send-keys -t "$PANE_ID" "claude" C-m
    tmux select-pane -t "$PANE_ID"
    exit
  fi
done

# Create a pane if none are available
tmux split-window -h "claude"
