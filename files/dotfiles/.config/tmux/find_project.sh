#!/bin/sh
# Fuzzy-find any tmux window across all sessions and jump to it.
# Runs the popup itself; bound directly to a tmux key.
#
# One colored dot per claude pane in the window (multiple sessions → multiple
# dots). Green = running quietly. Red = actively working ("esc to interrupt"
# visible on screen). Yellow = waiting for user input (marker file dropped by
# the Notification hook in claude-waiting-mark.sh).

set -eu

DEV="${HOME}/dev"
MAX_W=160
MAX_H=25
WAIT_DIR="${TMPDIR:-/tmp}/claude-waiting"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
list="$tmp/list"
sel="$tmp/sel"
raw="$tmp/raw"
dots_file="$tmp/dots"
panes_all="$tmp/panes_all"

# Snapshot every live pane once; drives both the claude-pane loop and stale-
# marker cleanup below.
tmux list-panes -a \
  -F '#{session_name}:#{window_index}	#{pane_id}	#{pane_current_command}' \
  >"$panes_all"

# Prune waiting markers whose panes no longer exist (Claude crashed / pane
# closed with the marker still in place).
if [ -d "$WAIT_DIR" ]; then
  live_ids=$(awk -F'\t' '{sub(/^%/, "", $2); print $2}' "$panes_all")
  for marker in "$WAIT_DIR"/*; do
    [ -e "$marker" ] || continue
    id=$(basename "$marker")
    printf '%s\n' "$live_ids" | grep -qx "$id" || rm -f "$marker"
  done
fi

# Claude panes only, tagged R / Y / G.
: >"$dots_file"
awk -F'\t' '$3 ~ /^claude(\.exe)?$/' "$panes_all" |
  while IFS='	' read -r target pane_id cmd; do
    if tmux capture-pane -p -t "$pane_id" 2>/dev/null | tail -n 5 | grep -q 'esc to interrupt'; then
      printf '%s\tR\n' "$target"
    elif [ -e "$WAIT_DIR/${pane_id#%}" ]; then
      printf '%s\tY\n' "$target"
    else
      printf '%s\tG\n' "$target"
    fi
  done >>"$dots_file"

# Prefer the middle pane's cwd (pane_index == 2, per the 3-pane layout in
# `central_three_panes.sh`) — side panes often run auxiliary tools whose cwd
# doesn't reflect the project. Falls back to the active pane's cwd for
# windows that don't follow the layout.
middle_file="$tmp/middle"
tmux list-panes -a \
  -F '#{session_name}:#{window_index}	#{pane_index}	#{pane_current_path}' |
  awk -F'\t' '$2==2 {print $1"\t"$3}' >"$middle_file"

: >"$raw"
tmux list-windows -a \
  -F '#{session_name}:#{window_index}	#{session_name}	#{pane_current_path}' |
  while IFS='	' read -r target sess abs; do
    mid=$(awk -F'\t' -v t="$target" '$1==t {print $2; exit}' "$middle_file")
    [ -n "$mid" ] && abs="$mid"
    dots=$(awk -F'\t' -v t="$target" '
      $1==t {
        if (n++) printf " "
        if ($2=="R")      printf "\033[31m●\033[0m"
        else if ($2=="Y") printf "\033[33m●\033[0m"
        else              printf "\033[32m●\033[0m"
      }' "$dots_file")
    # Collapse deep cwds to the enclosing repo/worktree root so the label
    # reads as "repo" or "repo/worktree" instead of "repo/src/foo/bar".
    # Prefer the git top-level; fall back to $DEV's first component when git
    # rev-parse fails (stale cwd, not-yet-a-repo). Skip everything else.
    root=$(git -C "$abs" rev-parse --show-toplevel 2>/dev/null || true)
    if [ -z "$root" ]; then
      case "$abs" in
      "$DEV"/*)
        rest="${abs#$DEV/}"
        root="$DEV/${rest%%/*}"
        ;;
      *) continue ;;
      esac
    fi
    # If the parent is itself a git repo (regular `.git` dir, or a bare repo
    # whose worktrees live one level deeper), this is a linked worktree of it —
    # show as "repo/worktree". Otherwise just the basename.
    parent=${root%/*}
    if [ -e "$parent/.git" ] || { [ -f "$parent/HEAD" ] && [ -f "$parent/config" ] && [ -d "$parent/refs" ]; }; then
      path="${parent##*/}/${root##*/}"
    else
      path="${root##*/}"
    fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$target" "$path" "$root" "$sess" "$dots" >>"$raw"
  done

[ -s "$raw" ] || exit 0

sort -f -t '	' -k2,2 -k3,3 -o "$raw" "$raw"

sess_w=$(awk -F'\t' '{if (length($2)>m) m=length($2)} END{print m+0}' "$raw")
path_w=$(awk -F'\t' '{if (length($3)>m) m=length($3)} END{print m+0}' "$raw")
abs_w=$(awk -F'\t' '{if (length($4)>m) m=length($4)} END{print m+0}' "$raw")

awk -F'\t' -v sw="$sess_w" -v pw="$path_w" -v aw="$abs_w" '
  { printf "%s\t%-*s  %-*s  %-*s  %s\n", $1, sw, $2, pw, $3, aw, $4, $5 }' "$raw" >"$list"

rows=$(wc -l <"$list" | tr -d ' ')
h=$((rows + 4))
# sess + 2 gap + path + 2 gap + abs + 2 gap + dots (~7 chars for 4 panes) + prefix
w=$((sess_w + path_w + abs_w + 6 + 7 + 4))
[ "$h" -gt "$MAX_H" ] && h="$MAX_H"
[ "$w" -gt "$MAX_W" ] && w="$MAX_W"

tmux display-popup -E -w "$w" -h "$h" \
  "fzf --ansi --reverse --delimiter='[ \t]+' --with-nth=2.. --nth=1 < '$list' > '$sel'" ||
  true

[ -s "$sel" ] || exit 0

target=$(cut -f1 <"$sel")
session=${target%%:*}

tmux switch-client -t "$session"
tmux select-window -t "$target"
