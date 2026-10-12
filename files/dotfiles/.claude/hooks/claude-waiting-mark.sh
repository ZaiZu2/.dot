#!/bin/sh
# Claude Code Notification hook: alert that Claude needs the user (blocked on
# an answer, or idle for a while), with a tmux status message and a macOS
# desktop banner.
#
# Wired into settings.json:
#   Notification -> claude-waiting-mark.sh mark
#
# The Claude picker (~/.config/tmux/find_claude.sh) takes its state dots from
# `claude agents --json` instead of marker files: a hook in a session moved to
# the background runs without $TMUX_PANE, so per-pane markers went stale.

set -eu

MODE="${1:-}"
cat >/dev/null 2>&1 || true

case "$MODE" in
mark)
  # Status-bar flash inside the tmux server the pane belongs to.
  if [ -n "${TMUX:-}" ] && command -v tmux >/dev/null 2>&1; then
    tmux display-message "claude waiting: ${TMUX_PANE:-?}" 2>/dev/null || true
  fi

  # macOS desktop banner — silent no-op on Linux.
  if command -v osascript >/dev/null 2>&1; then
    osascript -e 'display notification "Claude is waiting for input" with title "Claude" sound name "Ping"' \
      >/dev/null 2>&1 || true
  fi
  ;;
esac

exit 0
