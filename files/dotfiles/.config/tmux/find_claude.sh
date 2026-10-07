#!/bin/sh
# Fuzzy-find any running Claude pane across all sessions and jump to it.
# Runs the popup itself; bound to `prefix C-c` in tmux.conf.
#
# One row per Claude pane: state dot, the pane title Claude sets (its session
# name), project, cwd and tmux session, with a live preview of the pane's
# screen.
# The dot comes from marker files kept by the claude-waiting-mark.sh hooks:
# yellow = blocked mid-turn on an answer from the user, red = working on a
# turn, green = idle, ready for the next prompt.

set -eu

. "${0%/*}/picker_lib.sh"

WAIT_DIR="${TMPDIR:-/tmp}/claude-waiting"
WORK_DIR="${TMPDIR:-/tmp}/claude-working"
TAB=$(printf '\t')

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
list="$tmp/list"
sel="$tmp/sel"
raw="$tmp/raw"
panes="$tmp/panes"

tmux list-panes -a \
  -F "#{pane_id}${TAB}#{session_name}${TAB}#{pane_current_command}${TAB}#{pane_current_path}${TAB}#{pane_title}" \
  >"$panes"

# Rows are keyed for sorting: waiting panes first, then working, then idle;
# within a state by project and title.
: >"$raw"
live=" "
while IFS="$TAB" read -r pane_id sess cmd abs title; do
  id=${pane_id#%}
  live="$live$id "
  case "$cmd" in
  claude | claude.exe) ;;
  *) continue ;;
  esac
  if [ -e "$WAIT_DIR/$id" ]; then
    state=0
  elif [ -e "$WORK_DIR/$id" ]; then
    state=1
  else
    state=2
  fi
  # A Claude outside any project is still listed, under its cwd's basename.
  if project_root "$abs"; then
    project_label "$PROJECT_ROOT"
  else
    PROJECT_LABEL=${abs##*/}
  fi
  case "$abs" in
  "$HOME"*) cwd="~${abs#"$HOME"}" ;;
  *) cwd=$abs ;;
  esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$state" "$pane_id" "$sess" "$PROJECT_LABEL" "$title" "$cwd" >>"$raw"
done <"$panes"

# Prune markers whose panes no longer exist (Claude crashed / pane closed with
# the marker still in place).
for marker in "$WAIT_DIR"/* "$WORK_DIR"/*; do
  [ -e "$marker" ] || continue
  case "$live" in
  *" ${marker##*/} "*) ;;
  *) rm -f "$marker" ;;
  esac
done

if [ ! -s "$raw" ]; then
  tmux display-message "no claude panes"
  exit 0
fi

sort -f -t "$TAB" -k1,1 -k4,4 -k5,5 "$raw" |
  awk -F'\t' '
    BEGIN {
      tw = length("TITLE"); lw = length("PROJECT"); cw = length("PATH")
      # Longest "glyph + space" prefix: one character, or its bytes when awk
      # is not counting in UTF-8.
      glyph = (length("●") == 1) ? 2 : 5
    }
    {
      # Drop the status glyph Claude prefixes its title with.
      if (match($5, /^[^ -~]+ /) && RLENGTH <= glyph) $5 = substr($5, RLENGTH + 1)
      state[NR] = $1; id[NR] = $2; sess[NR] = $3; label[NR] = $4; title[NR] = $5; cwd[NR] = $6
      if (length($5) > tw) tw = length($5)
      if (length($4) > lw) lw = length($4)
      if (length($6) > cw) cw = length($6)
    }
    END {
      # Column header (fzf --header-lines=1). The dot is centered under it.
      printf "-\tSTATE  %-*s  %-*s  %-*s  %s\n", tw, "TITLE", lw, "PROJECT", cw, "PATH", "SESSION"
      for (i = 1; i <= NR; i++) {
        color = (state[i] == 0) ? 33 : (state[i] == 1) ? 31 : 32
        printf "%s\t  \033[%dm●\033[0m    %-*s  %-*s  %-*s  %s\n",
          id[i], color, tw, title[i], lw, label[i], cw, cwd[i], sess[i]
      }
    }' >"$list"

# The preview captures only the highlighted pane, on demand.
tmux display-popup -E -w 90% -h 80% -e "FZF_DEFAULT_OPTS=$PICKER_FZF_OPTS" \
  "fzf --ansi --reverse --header-lines=1 --delimiter='\t' --with-nth=2.. --preview-window=right,60%,border-bold \
    --preview='${0%/*}/picker_preview.sh {1}' < '$list' > '$sel'" ||
  true

[ -s "$sel" ] || exit 0

pane=$(cut -f1 <"$sel")
target=$(tmux display-message -t "$pane" -p '#{session_name}:#{window_index}' 2>/dev/null) || exit 0

tmux switch-client -t "${target%%:*}"
tmux select-window -t "$target"
tmux select-pane -t "$pane"
