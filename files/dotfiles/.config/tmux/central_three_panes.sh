#!/bin/bash
# Creates a three-pane tmux layout with a central focus pane (50% width) flanked by two side panes
# (25% width each). Sets the focused pane as the central one if not all panes are already created.
pane_count=$(tmux list-panes | wc -l)
if [ "$pane_count" -eq 1 ]; then
  tmux split-window -hbd -l 25% -c "#{pane_current_path}" # split to left
  tmux split-window -h -l 33% -c "#{pane_current_path}"
elif [ "$pane_count" -eq 2 ]; then
  # Set focused pane as central
  if [ $(tmux display-message -p '#P') -eq 1 ]; then
    tmux resize-pane -t 1 -x 75%
    tmux split-window -hb -l 33% -c "#{pane_current_path}"
  else
    tmux resize-pane -t 1 -x 25%
    tmux split-window -h -l 33% -c "#{pane_current_path}"
  fi
else # For 3 and more panes
  tmux resize-pane -t 1 -x 25%
  tmux resize-pane -t 2 -x 50%
  tmux resize-pane -t 3 -x 25%
fi
