#!/bin/sh
# Remind that the prompt cache of a Claude pane is about to expire: a desktop
# notification where the OS has one, and a tmux popup listing every pane with
# a pending reminder, from which one can jump to a pane.
#
# Started by ~/.claude/statusline.sh, once per expiry of a 1h cache.
#
# Usage: claude_cache_notify.sh <pane_id> <expires_at>
#        claude_cache_notify.sh --popup <answer_file> <rows>
#
# Reminders are kept in $QUEUE_DIR, one file per pane, and shown together in a
# single popup on the most recently used client: whichever invocation holds
# $QUEUE_DIR.lock presents them, the others only add to the directory. A
# reminder that cannot be shown yet (a picker is open, no client is attached)
# is retried until its cache has expired; one whose pane is gone or has been
# prompted again in the meantime is dropped.
#
# The second form is the body of the popup. It redraws itself as reminders
# arrive, run out or time passes. Up/Down (or k/j) select, Enter jumps to the
# selected pane, Esc dismisses; either way every listed reminder is done with.
# Other keys are ignored, so text typed while it pops up does nothing.

set -eu

CACHE_DIR="${CLAUDE_CACHE_DIR:-${TMPDIR:-/tmp}/claude-cache}"
QUEUE_DIR="$CACHE_DIR/queue"
LOCK="$QUEUE_DIR.lock"
RETRY=5
POPUP_W=72
MAX_ROWS=12
TAB=$(printf '\t')

# Reminders still worth showing, as "<expires_at> <pane number>" lines, the
# most urgent first. Stale ones are dropped on the way.
pending() {
  _now=$(date +%s)
  for _f in "$QUEUE_DIR"/*; do
    [ -f "$_f" ] || continue
    _id=${_f##*/}
    _exp=$(cat "$_f" 2>/dev/null || true)
    _current=
    if [ -r "$CACHE_DIR/$_id" ]; then
      read -r _current _ <"$CACHE_DIR/$_id" || true
    fi
    if [ -n "$_exp" ] && [ "$_exp" -gt "$_now" ] && [ "$_current" = "$_exp" ] &&
      tmux display-message -p -t "%$_id" '' >/dev/null 2>&1; then
      printf '%s %s\n' "$_exp" "$_id"
    else
      rm -f "$_f"
    fi
  done | sort -n
}

if [ "${1:-}" = --popup ]; then
  answer=$2 rows=$3
  # Tells the presenter the popup did open, whatever happens to it next.
  echo shown >"$answer"

  # One byte of input as two hex digits; empty when none came within the
  # timeout set with stty.
  read_key() {
    head -c 1 | od -An -tx1 | tr -d ' \n'
  }

  saved=$(stty -g)
  trap 'stty "$saved"; printf "\033[?25h"' EXIT
  stty -icanon -echo min 0 time 10
  printf '\033[?25l'

  selected=
  frame=
  while :; do
    list=$(pending | head -n "$MAX_ROWS")
    [ -n "$list" ] || exit 0
    count=$(printf '%s\n' "$list" | wc -l | tr -d ' ')
    # More reminders than the popup has rows for: have it opened again, taller.
    if [ "$count" -gt "$rows" ]; then
      echo reopen >"$answer"
      exit 0
    fi

    ids=$(printf '%s\n' "$list" | cut -d' ' -f2)
    printf '%s\n' "$ids" >"$answer.ids"
    case "$TAB$(printf '%s' "$ids" | tr '\n' "$TAB")$TAB" in
    *"$TAB$selected$TAB"*) ;;
    *) selected=$(printf '%s\n' "$ids" | head -n 1) ;;
    esac

    now=$(date +%s)
    new=$(
      printf '%s\n' "$list" | while read -r exp id; do
        where=$(tmux display-message -p -t "%$id" "#{session_name}:#{window_index}$TAB#{pane_title}" 2>/dev/null || true)
        printf '%s\t%sm\t%s\n' "$id" $(((exp - now + 59) / 60)) "$where"
      done | awk -F'\t' -v sel="$selected" -v width="$((POPUP_W - 6))" '
        BEGIN { glyph = (length("●") == 1) ? 2 : 5 }
        {
          # Drop the status glyph Claude prefixes its title with.
          if (match($4, /^[^ -~]+ /) && RLENGTH <= glyph) $4 = substr($4, RLENGTH + 1)
          id[NR] = $1; left[NR] = $2; where[NR] = $3; title[NR] = $4
          if (length($3) > ww) ww = length($3)
        }
        END {
          printf "\n  Claude cache about to expire:\n\n"
          for (i = 1; i <= NR; i++) {
            row = sprintf("%-3s  %-*s  %s", left[i], ww, where[i], title[i])
            row = substr(row, 1, width - 2)
            if (id[i] == sel) printf "  \033[1m> %s\033[0m\n", row
            else printf "    %s\n", row
          }
          printf "\n  Enter: jump to the pane   Esc: dismiss"
        }'
    )
    if [ "$new" != "$frame" ]; then
      frame=$new
      printf '\033[H\033[J%s' "$frame"
    fi

    key=$(read_key)
    move=
    case "$key" in
    0a | 0d)
      echo "jump $selected" >"$answer"
      exit 0
      ;;
    6b) move=up ;;
    6a) move=down ;;
    1b)
      # Esc on its own, or the start of an arrow key sequence.
      stty min 0 time 1
      key=$(read_key)
      if [ "$key" = 5b ] || [ "$key" = 4f ]; then
        case "$(read_key)" in
        41) move=up ;;
        42) move=down ;;
        esac
        stty min 0 time 10
      else
        exit 0
      fi
      ;;
    esac
    if [ -n "$move" ]; then
      selected=$(printf '%s\n' "$ids" | awk -v sel="$selected" -v move="$move" '
        { id[NR] = $0; if ($0 == sel) at = NR }
        END {
          at += (move == "up") ? -1 : 1
          if (at < 1) at = 1
          if (at > NR) at = NR
          print id[at]
        }')
    fi
  done
fi

pane=${1:?pane id}
expires=${2:?expiry in epoch seconds}

# The pane may be gone by now.
where=$(tmux display-message -p -t "$pane" '#{session_name}:#{window_index} #{pane_title}' 2>/dev/null) || exit 0
left=$((expires - $(date +%s)))
[ "$left" -gt 0 ] || left=0
msg="Claude cache expires in $(((left + 59) / 60))m: $where"

if command -v osascript >/dev/null 2>&1; then
  osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "Claude" sound name "Ping"' \
    -e 'end run' "$msg" >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null 2>&1; then
  notify-send Claude "$msg" >/dev/null 2>&1 || true
fi

mkdir -p "$QUEUE_DIR"
printf '%s\n' "$expires" >"$QUEUE_DIR/${pane#%}"

# Show the pending reminders on the most recently used client and act on the
# answer. Non-zero when the popup could not open.
present() {
  client=$(tmux list-clients -F '#{client_activity} #{client_name}' 2>/dev/null | sort -rn | head -n 1 | cut -d' ' -f2-)
  [ -n "$client" ] || return 1
  rows=$(pending | wc -l | tr -d ' ')
  [ "$rows" -le "$MAX_ROWS" ] || rows=$MAX_ROWS
  answer="$tmp/answer"
  rm -f "$answer" "$answer.ids"
  # A client that already shows a popup ignores the request without an error;
  # only the answer file tells whether this one opened.
  tmux display-popup -c "$client" -E -w "$POPUP_W" -h $((rows + 7)) -T ' claude cache ' \
    -e "CLAUDE_CACHE_DIR=$CACHE_DIR" "'$0' --popup '$answer' '$rows'" 2>/dev/null || true
  [ -s "$answer" ] || return 1

  read -r action jump_to <"$answer" || true
  [ "$action" != reopen ] || return 0
  # Answered: everything that was listed is done with.
  if [ -r "$answer.ids" ]; then
    while read -r id; do
      rm -f "$QUEUE_DIR/$id"
    done <"$answer.ids"
  fi
  if [ "$action" = jump ] && [ -n "$jump_to" ]; then
    target=$(tmux display-message -p -t "%$jump_to" '#{session_name}:#{window_index}' 2>/dev/null) || return 0
    tmux switch-client -c "$client" -t "${target%%:*}"
    tmux select-window -t "$target"
    tmux select-pane -t "%$jump_to"
  fi
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# A reminder added just as the presenter was leaving would be stranded, hence
# the look at the directory again after the lock is released.
while [ -n "$(pending)" ]; do
  if ! mkdir "$LOCK" 2>/dev/null; then
    holder=$(cat "$LOCK/pid" 2>/dev/null || true)
    if [ -n "$holder" ] && kill -0 "$holder" 2>/dev/null; then
      exit 0
    fi
    # Left behind by a presenter that was killed.
    rm -rf "$LOCK"
    continue
  fi
  echo $$ >"$LOCK/pid"
  trap 'rm -rf "$tmp" "$LOCK"' EXIT

  while [ -n "$(pending)" ]; do
    present || sleep "$RETRY"
  done

  rm -rf "$LOCK"
  trap 'rm -rf "$tmp"' EXIT
done
