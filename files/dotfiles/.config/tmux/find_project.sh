#!/bin/sh
# Fuzzy-find any tmux window across all sessions and jump to it.
# Runs the popup itself; bound to `prefix C-f` in tmux.conf.
#
# Building the list costs a fixed handful of processes however many windows
# exist: nothing below forks per window.

set -eu

. "${0%/*}/picker_lib.sh"

TAB=$(printf '\t')

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
list="$tmp/list"
sel="$tmp/sel"
raw="$tmp/raw"
wins="$tmp/wins"

# One line per window with the cwd to label it by. Prefer the middle pane's cwd
# (pane_index == 2, per the 3-pane layout in `central_three_panes.sh`) — side
# panes often run auxiliary tools whose cwd doesn't reflect the project. Falls
# back to the active pane's cwd for windows that don't follow the layout.
tmux list-panes -a \
  -F "#{session_name}:#{window_index}${TAB}#{session_name}${TAB}#{pane_index}${TAB}#{pane_active}${TAB}#{pane_current_path}" |
  awk -F'\t' '
    !($1 in sess) { order[++n] = $1; sess[$1] = $2 }
    $3 == 2 { mid[$1] = $5 }
    $4 == 1 { act[$1] = $5 }
    END {
      for (i = 1; i <= n; i++) {
        t = order[i]
        print t "\t" sess[t] "\t" (mid[t] != "" ? mid[t] : act[t])
      }
    }' >"$wins"

: >"$raw"
while IFS="$TAB" read -r target sess abs; do
  # Windows outside any repo and outside $DEV are skipped.
  project_root "$abs" || continue
  project_label "$PROJECT_ROOT"
  printf '%s\t%s\t%s\t%s\n' "$target" "$PROJECT_LABEL" "$PROJECT_ROOT" "$sess" >>"$raw"
done <"$wins"

[ -s "$raw" ] || exit 0

sort -f -t "$TAB" -k2,2 -k3,3 "$raw" |
  awk -F'\t' '
    BEGIN {
      # Row 0 is the column header (fzf --header-lines=1).
      t[0] = "-"; label[0] = "PROJECT"; root[0] = "PATH"; sess[0] = "SESSION"
      lw = length(label[0]); rw = length(root[0])
    }
    {
      t[NR] = $1; label[NR] = $2; root[NR] = $3; sess[NR] = $4
      if (length($2) > lw) lw = length($2)
      if (length($3) > rw) rw = length($3)
    }
    END {
      for (i = 0; i <= NR; i++)
        printf "%s\t%-*s  %-*s  %s\n", t[i], lw, label[i], rw, root[i], sess[i]
    }' >"$list"

# The preview shows the window's active pane, captured on demand for the
# highlighted row only.
tmux display-popup -E -w 75% -h 80% -e "FZF_DEFAULT_OPTS=$PICKER_FZF_OPTS" \
  "fzf --reverse --header-lines=1 --delimiter='[ \t]+' --with-nth=2.. --nth=1 --preview-window=right,60%,border-bold \
    --preview='${0%/*}/picker_preview.sh {1}' < '$list' > '$sel'" ||
  true

[ -s "$sel" ] || exit 0

target=$(cut -f1 <"$sel")
session=${target%%:*}

tmux switch-client -t "$session"
tmux select-window -t "$target"
