#!/bin/sh

if [ -z "$TMUX" ]; then
  echo "Not in a tmux session"
  exit 1
fi

# Prefer the claude connected to the IDE websocket port given as $1 (if any)
if [ -n "$1" ]; then
  CLAUDE_PID=$(lsof -nP -a -iTCP:"$1" -sTCP:ESTABLISHED -c claude -t 2>/dev/null | head -n 1)
  if [ -n "$CLAUDE_PID" ]; then
    CLAUDE_TTY="/dev/$(ps -o tty= -p "$CLAUDE_PID" | tr -d ' ')"
    PANE_ID=$(tmux list-panes -a -F "#{pane_tty} #{pane_id}" | awk -v tty="$CLAUDE_TTY" '$1 == tty {print $2}')
    if [ -n "$PANE_ID" ]; then
      tmux select-window -t "$PANE_ID"
      tmux select-pane -t "$PANE_ID"
      exit
    fi
  fi
fi

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
    tmux send-keys -t "$PANE_ID" "c" C-m
    tmux select-pane -t "$PANE_ID"
    exit
  fi
done

# Create a pane if none are available
tmux split-window -h "zsh -ic c"
