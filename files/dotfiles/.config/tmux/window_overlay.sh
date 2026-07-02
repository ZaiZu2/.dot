#!/bin/sh
# Fuzzy-find any tmux window across all sessions and jump to it.
# Runs the popup itself; bound directly to a tmux key.
#
# One colored dot per claude pane in the window (multiple sessions → multiple
# dots). Green = idle waiting for input. Red = actively working ("esc to
# interrupt" visible on screen).

set -eu

DEV="${HOME}/dev"
MAX_W=100
MAX_H=25

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
list="$tmp/list"
sel="$tmp/sel"
raw="$tmp/raw"
dots_file="$tmp/dots"

# One server-wide list-panes lists every pane running `claude` as its
# foreground command. Only those panes get a capture-pane check.
: > "$dots_file"
tmux list-panes -a \
  -F '#{session_name}:#{window_index}	#{pane_id}	#{pane_current_command}' \
| awk -F'\t' '$3 ~ /^claude(\.exe)?$/' \
| while IFS='	' read -r target pane_id cmd; do
    if tmux capture-pane -p -t "$pane_id" 2>/dev/null | tail -n 5 | grep -q 'esc to interrupt'; then
      printf '%s\tR\n' "$target"
    else
      printf '%s\tG\n' "$target"
    fi
  done >> "$dots_file"

: > "$raw"
tmux list-windows -a \
  -F '#{session_name}:#{window_index}	#{session_name}	#{pane_current_path}' \
| while IFS='	' read -r target sess path; do
    dots=$(awk -F'\t' -v t="$target" '
      $1==t {
        if (n++) printf " "
        if ($2=="R") printf "\033[31m●\033[0m"; else printf "\033[32m●\033[0m"
      }' "$dots_file")
    case "$path" in
      "$DEV"/*) path="${path#$DEV/}" ;;
      "$HOME"/*) path="~/${path#$HOME/}" ;;
    esac
    printf '%s\t%s\t%s\t%s\n' "$target" "$sess" "$path" "$dots" >> "$raw"
  done

[ -s "$raw" ] || exit 0

sess_w=$(awk -F'\t' '{if (length($2)>m) m=length($2)} END{print m+0}' "$raw")
path_w=$(awk -F'\t' '{if (length($3)>m) m=length($3)} END{print m+0}' "$raw")

awk -F'\t' -v sw="$sess_w" -v pw="$path_w" '
  { printf "%s\t%-*s  %-*s  %s\n", $1, sw, $2, pw, $3, $4 }' "$raw" > "$list"

rows=$(wc -l < "$list" | tr -d ' ')
h=$((rows + 4))
# sess + 2 gap + path + 2 gap + dots (~7 chars for 4 panes) + prefix
w=$((sess_w + path_w + 4 + 7 + 4))
[ "$h" -gt "$MAX_H" ] && h="$MAX_H"
[ "$w" -gt "$MAX_W" ] && w="$MAX_W"

tmux display-popup -E -w "$w" -h "$h" \
  "fzf --ansi --reverse --with-nth=2.. --delimiter='\t' < '$list' > '$sel'" \
  || true

[ -s "$sel" ] || exit 0

target=$(cut -f1 < "$sel")
session=${target%%:*}

tmux switch-client -t "$session"
tmux select-window -t "$target"
