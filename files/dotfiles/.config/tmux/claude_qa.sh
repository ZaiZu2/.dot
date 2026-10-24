#!/bin/sh
# Show the Q&A Claude, a Claude for quick, non-project questions, in a popup.
# Bound to `prefix C-q` in tmux.conf, which runs this script outside the Q&A
# session and closes the popup inside it (detach-client).
#
# The Q&A Claude is the command of the single pane of the hidden tmux session
# `_qa`, a name written literally here, in tmux.conf and in
# claude_sessions.sh (which leaves it out of the picker, pins and reminders).
# The popup only runs a nested `tmux attach`, so closing it detaches and the
# conversation keeps running. When Claude exits, the pane and `_qa` end with
# it, which closes the popup; the next run starts a fresh conversation.
#
# Claude runs in its own directory, since Claude Code trusts $HOME one
# session at a time only. DOT_CLAUDE_QA=1 in its environment tells
# ~/.claude/statusline.sh to start no prompt cache reminders for it; it
# identifies the Q&A Claude across /clear, which changes its session id.
set -eu

dir=$HOME/.local/share/claude-qa
mkdir -p "$dir"

if ! tmux has-session -t =_qa 2>/dev/null; then
  # A second run racing to create the session loses here, harmlessly.
  tmux new-session -d -s _qa -c "$dir" -e DOT_CLAUDE_QA=1 'claude --model sonnet --effort medium' 2>/dev/null || true
  # No status bar inside the popup.
  tmux set-option -t =_qa status off
fi

# Empty TMUX lets the popup's attach run nested, inside the client that opened it.
tmux display-popup -E -w 80% -h 80% -T ' claude q&a ' 'TMUX= tmux attach -t =_qa'
