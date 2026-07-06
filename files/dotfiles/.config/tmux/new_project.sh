#!/bin/sh
# Fuzzy-pick a git repo (or worktree) under ~/dev and open it in a new
# project window. Runs the popup itself; bound directly to a tmux key.

set -eu

DEV="${HOME}/dev"
MAX_W=160
MAX_H=25

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
list="$tmp/list"
sel="$tmp/sel"

for d in "$DEV"/*/; do
  d="${d%/}"
  if [ -e "$d/.git" ]; then
    # Regular repo (or worktree checkout). Only fork git if it has linked
    # worktrees; otherwise the top-level dir is the only entry.
    if [ -d "$d/.git/worktrees" ] && [ -n "$(ls -A "$d/.git/worktrees" 2>/dev/null)" ]; then
      git -C "$d" worktree list --porcelain 2>/dev/null |
        awk '/^worktree /{print $2}'
    else
      printf '%s\n' "$d"
    fi
  elif [ -f "$d/HEAD" ] && [ -f "$d/config" ] && [ -d "$d/refs" ]; then
    # Bare repo — its worktrees live one level deeper. Emit both the bare
    # dir itself (for git ops at the top level) and each checked-out worktree.
    printf '%s\n' "$d"
    git -C "$d" worktree list --porcelain 2>/dev/null |
      awk -v bare="$d" '/^worktree /{ if ($2 != bare) print $2 }'
  fi
done | sort -uf |
  awk -v dev="$DEV/" '
      { p=$0; if (index(p, dev)==1) p=substr(p, length(dev)+1);
        paths[NR]=$0; rels[NR]=p;
        if (length(p) > m) m=length(p) }
      END {
        for (i=1; i<=NR; i++)
          printf "%s\t%-*s  %s\n", paths[i], m, rels[i], paths[i]
      }' \
    >"$list"

rows=$(wc -l <"$list" | tr -d ' ')
[ "$rows" -eq 0 ] && exit 0

cols=$(awk -F'\t' '{ v=length($2); if (v>m) m=v } END{print m+0}' "$list")

h=$((rows + 4))
w=$((cols + 8))
[ "$h" -gt "$MAX_H" ] && h="$MAX_H"
[ "$w" -gt "$MAX_W" ] && w="$MAX_W"

tmux display-popup -E -w "$w" -h "$h" \
  "fzf --reverse --with-nth=2.. --delimiter='\t' < '$list' > '$sel'" ||
  true

[ -s "$sel" ] || exit 0

path=$(cut -f1 <"$sel")

# Second popup: pick target session, or type a new name.
# fzf --print-query emits the typed query on line 1 and the matched pick
# (if any) on line 2 — a typed-but-unmatched value becomes a new session.
sess_list="$tmp/sessions"
sess_sel="$tmp/sess_sel"
tmux list-sessions -F '#{session_name}' >"$sess_list"

sess_rows=$(wc -l <"$sess_list" | tr -d ' ')
sess_h=$((sess_rows + 4))
sess_w=40
[ "$sess_h" -gt "$MAX_H" ] && sess_h="$MAX_H"

tmux display-popup -E -w "$sess_w" -h "$sess_h" \
  "fzf --reverse --print-query --prompt='session> ' < '$sess_list' > '$sess_sel'" ||
  true

[ -s "$sess_sel" ] || exit 0

# Prefer the matched pick; fall back to the typed query for a new session.
session=$(sed -n '2p' <"$sess_sel")
[ -n "$session" ] || session=$(sed -n '1p' <"$sess_sel")
[ -n "$session" ] || exit 0

"$XDG_CONFIG_HOME/tmux/new_project_window.sh" -s "$session" "$path"
