#!/bin/sh
# Claude Code hook: mark / clear a per-pane "waiting for input" marker.
#
# Wired into settings.json:
#   Notification     -> claude-waiting-mark.sh mark
#   UserPromptSubmit -> claude-waiting-mark.sh clear
#
# Read by:
#   ~/.config/tmux/find_project.sh       (yellow dot)
#   ~/.config/tmux/jump_waiting_claude.sh (C-b C-c target)
#
# Marker key: $TMUX_PANE with the leading % stripped (e.g. %42 -> 42).
# When not in tmux, falls back to the hook JSON's session_id so the script
# stays a no-op-safe rather than exiting non-zero and blocking Claude.

set -eu

MODE="${1:-}"
WAIT_DIR="${TMPDIR:-/tmp}/claude-waiting"
mkdir -p "$WAIT_DIR"

INPUT=$(cat 2>/dev/null || true)

pane_key() {
  if [ -n "${TMUX_PANE:-}" ]; then
    printf '%s' "${TMUX_PANE#%}"
    return
  fi
  if [ -n "$INPUT" ] && command -v jq >/dev/null 2>&1; then
    jq -r '.session_id // empty' <<EOF
$INPUT
EOF
    return
  fi
  printf 'unknown'
}

KEY=$(pane_key)
[ -n "$KEY" ] || exit 0
MARKER="$WAIT_DIR/$KEY"

case "$MODE" in
mark)
  # Write marker (best-effort JSON body for later debugging).
  {
    printf '{"pane":"%s","tmux_pane":"%s"}\n' "$KEY" "${TMUX_PANE:-}"
  } >"$MARKER" 2>/dev/null || true

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
clear)
  rm -f "$MARKER" 2>/dev/null || true
  ;;
*)
  echo "usage: $(basename "$0") <mark|clear>" >&2
  exit 2
  ;;
esac

exit 0
