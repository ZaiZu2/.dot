#!/bin/sh
# fzf preview for the tmux pickers: the bottom of a pane's screen, colors kept.
# $1 = tmux target (a pane id, or a window for its active pane).
#
# Trailing blank lines are dropped first, so a mostly empty shell pane shows
# its prompt instead of the blank area below it.

tmux capture-pane -ep -t "$1" 2>/dev/null |
  awk -v n="${FZF_PREVIEW_LINES:-40}" '
    { line[NR] = $0; if ($0 ~ /[^ \t]/) last = NR }
    END {
      first = last - n + 1
      if (first < 1) first = 1
      for (i = first; i <= last; i++) print line[i]
    }'
