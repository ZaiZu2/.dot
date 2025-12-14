#!/bin/sh

if [ -z "$TMUX" ]; then
  echo "Not in a tmux session"
  exit 1
fi

PANE_COUNT=$(tmux list-panes | wc -l)
# Find pane running claude
CLAUDE_PROC_NAME=$(claude --version | sed 's/ .*//; s/\./\\./g') # Claude uses version to name its proc name
CLAUDE_PANE=$(tmux list-panes -F "#{pane_id}:#{pane_current_command}" | grep "$CLAUDE_PROC_NAME" | cut -d : -f1)

if [ -n "$CLAUDE_PANE" ]; then
  # Pane exists, focus it
  tmux select-pane -t "$CLAUDE_PANE"
elif [ "$PANE_COUNT" -eq 3 ]; then
  # Check if 3rd pane (index 2) is idle
  PANE_PID=$(tmux display-message -p -t 2 '#{pane_pid}')
  PANE_CMD=$(tmux display-message -p -t 2 '#{pane_current_command}')

  # Check if it's a shell with no child processes
  case "$PANE_CMD" in
  zsh | bash | sh | fish)
    if ! pgrep -P "$PANE_PID" >/dev/null 2>&1; then
      # 3rd pane is idle, send claude command to it
      tmux send-keys -t 2 "claude" C-m
      tmux select-pane -t 2
    else
      # Shell has active child processes, create new split
      tmux split-window -h "claude"
    fi
    ;;
  *)
    # 3rd pane has active process, create new split
    tmux split-window -h "claude"
    ;;
  esac
else
  # Not 3 panes, create new split
  tmux split-window -h "claude"
fi
