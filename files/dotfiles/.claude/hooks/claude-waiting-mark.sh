#!/bin/sh
# Claude Code hook: track a per-pane state (working / waiting / idle) in marker
# files, for the Claude picker's state dots.
#
# Wired into settings.json:
#   UserPromptSubmit -> claude-waiting-mark.sh work    (turn started)
#   Notification     -> claude-waiting-mark.sh mark    (blocked on the user)
#   PostToolUse      -> claude-waiting-mark.sh resume  (unblocked, still working)
#   Stop, SessionEnd -> claude-waiting-mark.sh idle    (turn finished)
#
# Markers, read by ~/.config/tmux/find_claude.sh:
#   $WAIT_DIR/<key>  waiting: Claude needs an answer mid-turn (yellow dot)
#   $WORK_DIR/<key>  working: a turn is in progress (red dot)
#   neither          idle: ready for the next prompt (green dot)
#
# Marker key: $TMUX_PANE with the leading % stripped (e.g. %42 -> 42).
# When not in tmux, falls back to the hook JSON's session_id so the script
# stays a no-op-safe rather than exiting non-zero and blocking Claude.
#
# Stop does not fire when a turn is interrupted with Esc, so such a pane stays
# "working" until its next turn ends.

set -eu

MODE="${1:-}"
WAIT_DIR="${TMPDIR:-/tmp}/claude-waiting"
WORK_DIR="${TMPDIR:-/tmp}/claude-working"
mkdir -p "$WAIT_DIR" "$WORK_DIR"

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
WORKING="$WORK_DIR/$KEY"

case "$MODE" in
work)
  rm -f "$MARKER" 2>/dev/null || true
  : >"$WORKING" 2>/dev/null || true
  ;;
mark)
  # The "idle for a while" notification is not a mid-turn block: the pane is
  # just idle, so it gets the alert below but no waiting marker.
  case "$INPUT" in
  *idle_prompt*) ;;
  *)
    # Write marker (best-effort JSON body for later debugging).
    {
      printf '{"pane":"%s","tmux_pane":"%s"}\n' "$KEY" "${TMUX_PANE:-}"
    } >"$MARKER" 2>/dev/null || true
    ;;
  esac

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
resume | clear)
  rm -f "$MARKER" 2>/dev/null || true
  ;;
idle)
  rm -f "$MARKER" "$WORKING" 2>/dev/null || true
  ;;
*)
  echo "usage: $(basename "$0") <work|mark|resume|idle>" >&2
  exit 2
  ;;
esac

exit 0
