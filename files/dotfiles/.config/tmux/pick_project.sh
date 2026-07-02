#!/bin/sh
# Fuzzy-pick a git repo (or worktree) under ~/dev and open it in a new
# project window. Runs the popup itself; bound directly to a tmux key.

set -eu

DEV="${HOME}/dev"
MAX_W=100
MAX_H=25

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
list="$tmp/list"
sel="$tmp/sel"

for d in "$DEV"/*/; do
  d="${d%/}"
  # Skip non-repos with a plain filesystem check (no git fork).
  [ -e "$d/.git" ] || continue
  # Only fork git for repos that actually have linked worktrees.
  if [ -d "$d/.git/worktrees" ] && [ -n "$(ls -A "$d/.git/worktrees" 2>/dev/null)" ]; then
    git -C "$d" worktree list --porcelain 2>/dev/null \
      | awk '/^worktree /{print $2}'
  else
    printf '%s\n' "$d"
  fi
done | sort -u \
  | awk -v dev="$DEV/" '
      { p=$0; if (index(p, dev)==1) p=substr(p, length(dev)+1); print $0 "\t" p }' \
> "$list"

rows=$(wc -l < "$list" | tr -d ' ')
[ "$rows" -eq 0 ] && exit 0

cols=$(awk -F'\t' '{ v=length($2); if (v>m) m=v } END{print m+0}' "$list")

h=$((rows + 4))
w=$((cols + 8))
[ "$h" -gt "$MAX_H" ] && h="$MAX_H"
[ "$w" -gt "$MAX_W" ] && w="$MAX_W"

tmux display-popup -E -w "$w" -h "$h" \
  "fzf --reverse --with-nth=2.. --delimiter='\t' < '$list' > '$sel'" \
  || true

[ -s "$sel" ] || exit 0

path=$(cut -f1 < "$sel")

"$XDG_CONFIG_HOME/tmux/new_project_window.sh" "$path"
