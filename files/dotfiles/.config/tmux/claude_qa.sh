#!/bin/sh
# Show the Q&A Claude, a Claude for quick, non-project questions, in a popup.
# Bound to `prefix C-q` in tmux.conf, which also defines the key tables
# `qa` and `qa-prefix` that close the popup.
#
# The Q&A Claude is the command of the single pane of the hidden tmux session
# `_qa`, a name written literally here, in tmux.conf, in claude_sessions.sh
# (which leaves it out of the picker, pins and reminders) and in
# new_project.sh (which offers no project window in it).
# The popup only runs a nested `tmux attach`, so closing it detaches and the
# conversation keeps running. When Claude exits, the pane and `_qa` end with
# it, which closes the popup; the next run starts a fresh conversation.
#
# Claude runs in its own directory, since Claude Code trusts $HOME one
# session at a time only. DOT_CLAUDE_QA=1 in its environment tells
# ~/.claude/statusline.sh to start no prompt cache reminders for it; it
# identifies the Q&A Claude across /clear, which changes its session id.
#
# Inside the popup no other tmux binding works: `_qa` has no prefix and its
# own key table `qa` instead of root, so C-b C-q closes the popup, C-b C-b
# sends C-b and every other key goes to Claude. The global bindings would
# run against the popup's nested client: a jump (M-1..M-4) or a picker would
# open its target inside the popup.
set -eu

dir=$HOME/.local/share/claude-qa
mkdir -p "$dir"

if ! tmux has-session -t =_qa 2>/dev/null; then
  # A second run racing to create the session loses here, harmlessly.
  tmux new-session -d -s _qa -c "$dir" -e DOT_CLAUDE_QA=1 'claude --model sonnet --effort medium' 2>/dev/null || true
  # No status bar inside the popup, and only the bindings of the `qa` table.
  tmux set-option -t =_qa: status off \; set-option -t =_qa: prefix None \; set-option -t =_qa: key-table qa
fi

# Empty TMUX lets the popup's attach run nested, inside the client that opened it.
tmux display-popup -E -w 80% -h 80% -T ' claude q&a ' 'TMUX= tmux attach -t =_qa'
