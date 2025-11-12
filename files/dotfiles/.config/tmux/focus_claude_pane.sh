#!/bin/sh

if [ -z "$TMUX" ]; then
  echo "Not in a tmux session"
  exit 1
fi

# Find pane running claude
CLAUDE_PANE=$(tmux list-panes -F "#{pane_id}:#{pane_current_command}" | grep "2\.0\.37$" | cut -d : -f1)

if [ -n "$CLAUDE_PANE" ]; then
  # Pane exists, focus it
  tmux select-pane -t "$CLAUDE_PANE"
else
  # Create new pane and run claude
  tmux split-window -h "claude"
fi
