#!/bin/sh
# Pin up to four Claudes to tmux keys and jump to them from anywhere.
# Bound in tmux.conf: `M-1`..`M-4` jump, `prefix M-1`..`M-4` pin the Claude of
# the current pane; the Claude picker (find_claude.sh) pins and unpins rows
# with alt-1..alt-4 / alt-0.
#
# Usage: claude_pins.sh pin <1-4> <pane_id>
#        claude_pins.sh unpin <pane_id|session_id>
#        claude_pins.sh jump <1-4>
#
# A pin targets a session by its id, so it follows the session to whichever
# pane shows it; a pane running a Claude no session was tied to (a "?" row of
# claude_sessions.sh) is pinned by its pane id, with the tmux server's start
# time, since pane ids are reused by a new server. Nothing is cached: every
# use looks the target up in claude_sessions again.
#
# Pins are kept in $CLAUDE_STATE_DIR/pins/<n>, one line, tab-separated:
#   session <session_id> <title>
#   pane    <pane_id> <start_time> <title>
# The title (without Claude's status glyph) only names the pin in messages.
# A target sits in at most one slot: pinning it moves it there.
#
# pin    pins the Claude of a pane to slot n; a pane with no Claude row
#        changes nothing.
# unpin  removes the pin of a session, or of a pane: the pin of the session
#        shown in it, or its own pane pin. Silent when there is none.
# jump   switches to the pinned pane. A session without a pane (moved to the
#        background) keeps its pin; one no longer listed, or a pane that is
#        gone or belongs to an earlier tmux server, loses it.
# When `claude agents` fails, nothing is pinned, unpinned or cleared: without
# the session list every Claude pane would look like a "?" row.
# Messages go to the tmux status line.

set -eu

. "${0%/*}/claude_sessions.sh"

PINS_DIR="$CLAUDE_STATE_DIR/pins"
TAB=$(printf '\t')

usage() {
  echo "usage: ${0##*/} pin <1-4> <pane_id> | unpin <pane_id|session_id> | jump <1-4>" >&2
  exit 2
}

# say <message>: show it in the status line; `#` is literal, not a format.
say() {
  tmux display-message "$(printf '%s' "$1" | sed 's/#/##/g')" 2>/dev/null || true
}

# slot <n>: accept a pin slot (1-4); anything else prints the usage and exits.
slot() {
  case "${1:-}" in
  1 | 2 | 3 | 4) ;;
  *) usage ;;
  esac
}

# read_pin <n>: sets PIN_KIND, PIN_ID, PIN_START (pane pins only) and
# PIN_TITLE from pins/<n>; non-zero when the slot is empty.
read_pin() {
  PIN_KIND='' PIN_ID='' PIN_START='' PIN_TITLE=''
  [ -s "$PINS_DIR/$1" ] || return 1
  PIN_KIND=$(cut -f1 <"$PINS_DIR/$1")
  PIN_ID=$(cut -f2 <"$PINS_DIR/$1")
  if [ "$PIN_KIND" = pane ]; then
    PIN_START=$(cut -f3 <"$PINS_DIR/$1")
    PIN_TITLE=$(cut -f4- <"$PINS_DIR/$1")
  else
    PIN_TITLE=$(cut -f3- <"$PINS_DIR/$1")
  fi
}

# row_by <field> <value>: sets ROW_PANE, ROW_SESSION, ROW_SHORT and ROW_TITLE
# (glyph dropped) from the first row of $rows whose field (2 pane, 3 session)
# is value; non-zero when there is none.
row_by() {
  _row=$(awk -F"$CLAUDE_SEP" -v OFS="$CLAUDE_SEP" -v f="$1" -v v="$2" '
    BEGIN { glyph = (length("●") == 1) ? 2 : 5 }
    $f == v {
      # Drop the status glyph Claude prefixes its title with.
      t = $6
      if (match(t, /^[^ -~]+ /) && RLENGTH <= glyph) t = substr(t, RLENGTH + 1)
      print $2, $3, $4, t
      exit
    }' "$rows")
  [ -n "$_row" ] || return 1
  IFS="$CLAUDE_SEP" read -r ROW_PANE ROW_SESSION ROW_SHORT ROW_TITLE <<EOF
$_row
EOF
}

# pinned <n> <kind> <id> <start>: whether slot n holds that target.
pinned() {
  read_pin "$1" || return 1
  [ "$PIN_KIND" = "$2" ] && [ "$PIN_ID" = "$3" ] && [ "$PIN_START" = "$4" ]
}

# start_time: print the start time of the tmux server (empty when tmux is not
# reachable). Pane ids restart from %0 with a new server, so a pane pin is
# valid only while this value matches the one stored in it.
start_time() {
  tmux display-message -p '#{start_time}' 2>/dev/null || true
}

[ $# -ge 1 ] || usage
cmd=$1
shift
case "$cmd" in
pin)
  [ $# -eq 2 ] && [ -n "$2" ] || usage
  slot "$1"
  ;;
unpin) [ $# -eq 1 ] && [ -n "$1" ] || usage ;;
jump)
  [ $# -eq 1 ] || usage
  slot "$1"
  ;;
*) usage ;;
esac

if [ "$cmd" = jump ] && ! read_pin "$1"; then
  say "pin $1: empty"
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
rows="$tmp/rows"
if ! claude_sessions "$rows"; then
  say "pin: claude agents failed"
  exit 0
fi
now_start=$(start_time)

case "$cmd" in
pin)
  n=$1
  if ! row_by 2 "$2"; then
    say "pin: no claude in this pane"
    exit 0
  fi
  if [ -n "$ROW_SESSION" ]; then
    kind=session id=$ROW_SESSION start=
    line="session$TAB$ROW_SESSION$TAB$ROW_TITLE"
  else
    kind=pane id=$ROW_PANE start=$now_start
    line="pane$TAB$ROW_PANE$TAB$now_start$TAB$ROW_TITLE"
  fi
  mkdir -p "$PINS_DIR"
  for m in 1 2 3 4; do
    [ "$m" != "$n" ] || continue
    if pinned "$m" "$kind" "$id" "$start"; then rm -f "$PINS_DIR/$m"; fi
  done
  new=$(mktemp "$PINS_DIR/.new.XXXXXX")
  printf '%s\n' "$line" >"$new"
  mv "$new" "$PINS_DIR/$n"
  say "pin $n: $ROW_TITLE"
  ;;

unpin)
  # The session shown in that pane, if the argument is a pane.
  shown=
  if row_by 2 "$1"; then shown=$ROW_SESSION; fi
  for m in 1 2 3 4; do
    read_pin "$m" || continue
    case "$PIN_KIND" in
    session) [ "$PIN_ID" = "$1" ] || { [ -n "$shown" ] && [ "$PIN_ID" = "$shown" ]; } || continue ;;
    pane) [ "$PIN_ID" = "$1" ] && [ "$PIN_START" = "$now_start" ] || continue ;;
    *) continue ;;
    esac
    rm -f "$PINS_DIR/$m"
  done
  ;;

jump)
  n=$1
  found=
  case "$PIN_KIND" in
  session) row_by 3 "$PIN_ID" && found=1 ;;
  pane) [ "$PIN_START" = "$now_start" ] && row_by 2 "$PIN_ID" && found=1 ;;
  esac
  if [ -z "$found" ]; then
    rm -f "$PINS_DIR/$n"
    say "pin $n: $PIN_TITLE is gone"
    exit 0
  fi
  if [ -z "$ROW_PANE" ]; then
    say "pin $n: $PIN_TITLE runs in the background (claude attach ${ROW_SHORT:-${ROW_SESSION%%-*}})"
    exit 0
  fi
  if ! target=$(tmux display-message -t "$ROW_PANE" -p '#{session_name}:#{window_index}' 2>/dev/null); then
    rm -f "$PINS_DIR/$n"
    say "pin $n: $PIN_TITLE is gone"
    exit 0
  fi
  tmux switch-client -t "${target%%:*}"
  tmux select-window -t "$target"
  tmux select-pane -t "$ROW_PANE"
  ;;
esac
