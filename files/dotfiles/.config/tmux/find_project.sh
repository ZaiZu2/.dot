#!/bin/sh
# Fuzzy-find any tmux window across all sessions and jump to it.
# Runs the popup itself; bound to `prefix C-f` in tmux.conf.
#
# Building the list costs a fixed handful of processes however many windows
# exist: nothing below forks per window.
#
# The popup is sized from its content (see picker_size): the list as wide as
# its columns, the preview as wide as the widest active pane it can show,
# capped at 90% of the client. `--dry-run` prints the computed widths and
# opens nothing; PICKER_CLIENT_W replaces the client's width.

set -eu

. "${0%/*}/picker_lib.sh"

dry_run=
[ "${1:-}" = "--dry-run" ] && dry_run=1

# The screen width the popup is sized against, read before the popup opens.
client_w=${PICKER_CLIENT_W:-$(tmux display-message -p '#{client_width}')}

TAB=$(printf '\t')

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
list="$tmp/list"
sel="$tmp/sel"
raw="$tmp/raw"
wins="$tmp/wins"
widths="$tmp/widths"

# One line per window with the cwd to label it by. Prefer the middle pane's cwd
# (pane_index == 2, per the 3-pane layout in `central_three_panes.sh`) — side
# panes often run auxiliary tools whose cwd doesn't reflect the project. Falls
# back to the active pane's cwd for windows that don't follow the layout.
tmux list-panes -a \
  -F "#{session_name}:#{window_index}${TAB}#{session_name}${TAB}#{pane_index}${TAB}#{pane_active}${TAB}#{pane_current_path}${TAB}#{pane_width}" |
  awk -F'\t' '
    !($1 in sess) { order[++n] = $1; sess[$1] = $2 }
    $3 == 2 { mid[$1] = $5 }
    $4 == 1 { act[$1] = $5; pw[$1] = $6 }
    END {
      for (i = 1; i <= n; i++) {
        t = order[i]
        print t "\t" sess[t] "\t" (mid[t] != "" ? mid[t] : act[t]) "\t" pw[t]
      }
    }' >"$wins"

: >"$raw"
while IFS="$TAB" read -r target sess abs pw; do
  # Windows outside any repo and outside $DEV are skipped. The project is
  # shown by its root's path: relative to $DEV when under it, which also names
  # a worktree "repo/worktree", else with `~`.
  project_root "$abs" || continue
  picker_short_path "$PROJECT_ROOT"
  printf '%s\t%s\t%s\t%s\n' "$target" "$PICKER_PATH" "$sess" "$pw" >>"$raw"
done <"$wins"

[ -s "$raw" ] || exit 0

sort -f -t "$TAB" -k2,2 "$raw" |
  awk -F'\t' -v widths="$widths" '
    BEGIN {
      # Row 0 is the column header (fzf --header-lines=1).
      t[0] = "-"; label[0] = "PROJECT"; sess[0] = "SESSION"
      lw = length(label[0]); sw = length(sess[0])
    }
    {
      t[NR] = $1; label[NR] = $2; sess[NR] = $3
      if (length($2) > lw) lw = length($2)
      if (length($3) > sw) sw = length($3)
      if ($4 + 0 > pmax) pmax = $4 + 0
    }
    END {
      for (i = 0; i <= NR; i++)
        printf "%s\t%-*s  %s\n", t[i], lw, label[i], sess[i]
      # Widest list line (columns and the gap) and widest active pane.
      print lw + 2 + sw, pmax + 0 > widths
    }' >"$list"

read -r list_w preview_w <"$widths"
picker_size "$list_w" "$preview_w" "$client_w"

if [ -n "$dry_run" ]; then
  echo "list=$list_w preview=$PICKER_PREVIEW_W popup=$PICKER_POPUP_W client=$client_w"
  exit 0
fi

preview_opts=
if [ "$PICKER_PREVIEW_W" -gt 0 ]; then
  preview_opts="--preview-window=right,$PICKER_PREVIEW_W,border-bold --preview='${0%/*}/picker_preview.sh {1}'"
fi

# The preview shows the window's active pane, captured on demand for the
# highlighted row only.
tmux display-popup -E -w "$PICKER_POPUP_W" -h 80% -e "FZF_DEFAULT_OPTS=$PICKER_FZF_OPTS" \
  "fzf --reverse --header-lines=1 --delimiter='[ \t]+' --with-nth=2.. --nth=1 $preview_opts < '$list' > '$sel'" ||
  true

[ -s "$sel" ] || exit 0

target=$(cut -f1 <"$sel")
session=${target%%:*}

tmux switch-client -t "$session"
tmux select-window -t "$target"
