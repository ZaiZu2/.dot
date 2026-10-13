#!/bin/sh
# Fuzzy-find any running Claude across all tmux sessions and jump to it.
# Runs the popup itself; bound to `prefix C-c` in tmux.conf.
#
# Rows come from claude_sessions.sh: every session `claude agents --json`
# lists, tied to its tmux pane where the process tree or a unique title and
# cwd match allows, plus every pane running a Claude client no session was
# tied to (agent view or `claude attach`). Nothing is left out.
#
# Columns: state dot, time left on the prompt cache, title, project, cwd and
# tmux session, with a live preview of the pane's screen.
# The dot is the session's status: yellow = waiting on the user, red =
# working, green = idle; a grey "?" when no session is known for the pane.
# The cache column comes from the expiry ~/.claude/statusline.sh keeps per
# session: minutes until the cache goes cold, "cold" after that, "-" if
# unknown.
# The popup is sized from its content (see picker_size): the list as wide as
# its columns, the preview as wide as the widest pane it can show, capped at
# 90% of the client. `--dry-run` prints the computed widths and opens nothing;
# PICKER_CLIENT_W replaces the client's width.
# A session with no pane found shows "◌ bg <id>" as its tmux session: it runs
# in the background and may still be on screen in one of the "?" panes, when
# the match was ambiguous. Enter does nothing on it.

set -eu

dry_run=
[ "${1:-}" = "--dry-run" ] && dry_run=1

. "${0%/*}/picker_lib.sh"
. "${0%/*}/claude_sessions.sh"

TAB=$(printf '\t')

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
list="$tmp/list"
sel="$tmp/sel"
raw="$tmp/raw"
rows="$tmp/rows"
mkdir "$tmp/card"

pruning=1
claude_sessions "$rows" || pruning=

if [ ! -s "$rows" ]; then
  tmux display-message "no claude sessions"
  exit 0
fi

# Rows are keyed for sorting: Claudes in a pane first, background sessions
# last; within each by project, then path. The first field is the group digit
# then the state digit.
: >"$raw"
now=$(date +%s)
while IFS="$CLAUDE_SEP" read -r state pane session short sess title abs expires; do
  cache=-
  if [ -n "$expires" ]; then
    if [ "$expires" -gt "$now" ]; then
      cache="$(((expires - now + 59) / 60))m"
    else
      cache=cold
    fi
  fi
  # A Claude outside any project is still listed, under its cwd's basename.
  if project_root "$abs"; then
    project_label "$PROJECT_ROOT"
  else
    PROJECT_LABEL=${abs##*/}
  fi
  picker_short_path "$abs"
  cwd=$PICKER_PATH
  group=0
  if [ -n "$pane" ]; then
    key=$pane
  else
    group=1
    short=${short:-${session%%-*}}
    key="bg:$short"
    sess="◌ bg $short"
    printf '%s\n\n  id:      %s\n  session: %s\n  cwd:     %s\n\n  Runs in the background; no tmux pane found.\n  Open it with: claude attach %s\n' \
      "$title" "$short" "$session" "$cwd" "$short" >"$tmp/card/$key"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$group$state" "$key" "$sess" "$PROJECT_LABEL" "$title" "$cwd" "$cache" >>"$raw"
done <"$rows"

# Drop the cache files of sessions that are gone. Skipped when `claude agents`
# failed: every session would look gone. A dry run deletes nothing.
if [ -n "$pruning" ] && [ -z "$dry_run" ]; then
  live=" $(cut -d "$CLAUDE_SEP" -f3 "$rows" | tr '\n' ' ') "
  for f in "$CLAUDE_CACHE_DIR"/* "$CLAUDE_CACHE_DIR"/notified/*; do
    [ -f "$f" ] || continue
    case "$live" in
    *" ${f##*/} "*) ;;
    *) rm -f "$f" ;;
    esac
  done
fi

# Pane widths by pane id, for the preview width.
panew="$tmp/panew"
tmux list-panes -a -F "#{pane_id}${TAB}#{pane_width}" >"$panew" 2>/dev/null || : >"$panew"
widths="$tmp/widths"

sort -f -t "$TAB" -k1.1,1.1 -k4,4 -k6,6 "$raw" |
  awk -F'\t' -v panew="$panew" -v carddir="$tmp/card" -v widths="$widths" '
    BEGIN {
      while ((getline line < panew) > 0) {
        split(line, f, "\t")
        pw[f[1]] = f[2]
      }
      sw = length("SESSION"); pvw = 0
      tw = length("TITLE"); lw = length("PROJECT"); cw = length("PATH")
      # Longest "glyph + space" prefix: one character, or its bytes when awk
      # is not counting in UTF-8.
      glyph = (length("●") == 1) ? 2 : 5
    }
    {
      # Drop the status glyph Claude prefixes its title with.
      if (match($5, /^[^ -~]+ /) && RLENGTH <= glyph) $5 = substr($5, RLENGTH + 1)
      state[NR] = substr($1, 2); id[NR] = $2; sess[NR] = $3; label[NR] = $4; title[NR] = $5; cwd[NR] = $6; cache[NR] = $7
      if (length($5) > tw) tw = length($5)
      if (length($4) > lw) lw = length($4)
      if (length($6) > cw) cw = length($6)
      if (length($3) > sw) sw = length($3)
      if ($2 ~ /^bg:/) {
        # A card has no pane: its longest line is the preview width.
        while ((getline line < (carddir "/" $2)) > 0) if (length(line) > pvw) pvw = length(line)
        close(carddir "/" $2)
      } else if (($2 in pw) && pw[$2] + 0 > pvw) pvw = pw[$2] + 0
    }
    END {
      # Column header (fzf --header-lines=1). The dot is centered under it.
      printf "-\tSTATE  CACHE  %-*s  %-*s  %-*s  %s\n", tw, "TITLE", lw, "PROJECT", cw, "PATH", "SESSION"
      for (i = 1; i <= NR; i++) {
        color = (state[i] == 0) ? 33 : (state[i] == 1) ? 31 : (state[i] == 2) ? 32 : 90
        dot = (state[i] == 3) ? "?" : "●"
        s = (id[i] ~ /^bg:/) ? "\033[2m" sess[i] "\033[0m" : sess[i]
        printf "%s\t  \033[%dm%s\033[0m    %-5s  %-*s  %-*s  %-*s  %s\n",
          id[i], color, dot, cache[i], tw, title[i], lw, label[i], cw, cwd[i], s
      }
      # Widest list line: the 14 columns before the title, the four padded
      # columns with their two-space gaps, and the session column.
      print 14 + tw + 2 + lw + 2 + cw + 2 + sw, pvw > widths
    }' >"$list"

read -r list_w preview_w <"$widths"
client_w=${PICKER_CLIENT_W:-$(tmux display-message -p '#{client_width}')}
picker_size "$list_w" "$preview_w" "$client_w"

if [ -n "$dry_run" ]; then
  echo "list=$list_w preview=$PICKER_PREVIEW_W popup=$PICKER_POPUP_W client=$client_w"
  exit 0
fi

preview_opts=
if [ "$PICKER_PREVIEW_W" -gt 0 ]; then
  preview_opts="--preview-window=right,$PICKER_PREVIEW_W,border-bold --preview='cat $tmp/card/{1} 2>/dev/null || ${0%/*}/picker_preview.sh {1}'"
fi

# The preview captures only the highlighted pane, on demand; a background
# session without pane gets its card instead.
tmux display-popup -E -w "$PICKER_POPUP_W" -h 80% -e "FZF_DEFAULT_OPTS=$PICKER_FZF_OPTS" \
  "fzf --ansi --reverse --header-lines=1 --delimiter='\t' --with-nth=2.. $preview_opts < '$list' > '$sel'" ||
  true

[ -s "$sel" ] || exit 0

pane=$(cut -f1 <"$sel")
case "$pane" in bg:*) exit 0 ;; esac
target=$(tmux display-message -t "$pane" -p '#{session_name}:#{window_index}' 2>/dev/null) || exit 0

tmux switch-client -t "${target%%:*}"
tmux select-window -t "$target"
tmux select-pane -t "$pane"
