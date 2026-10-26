#!/bin/sh
# Fuzzy-find any running Claude across all tmux sessions and jump to it.
# Runs the popup itself; bound to `prefix C-c` in tmux.conf.
#
# Rows come from claude_sessions.sh: every session `claude agents --json`
# lists, tied to its tmux pane where the process tree or a unique title and
# cwd match allows, plus every pane running a Claude client no session was
# tied to (agent view or `claude attach`). Nothing is left out.
#
# Columns: state dot, pin slot, time left on the prompt cache, title, project
# and tmux session, with a live preview of the pane's screen. The project is
# shown by its root's path: relative to ~/dev when under it, else with `~`.
# The dot is the session's status: yellow = waiting on the user, red =
# working, green = idle; a grey "?" when no session is known for the pane.
# The pin column shows the slot (1-4) the row is pinned to by claude_pins.sh,
# blank when unpinned.
# The cache column comes from the expiry ~/.claude/statusline.sh keeps per
# session in $CLAUDE_STATE_DIR/expiry/: minutes until the cache goes cold,
# "cold" after that, "-" if unknown. Opening the picker prunes the expiry/
# and notified/ files of sessions that are gone, and of the Q&A Claude, which
# claude_sessions.sh leaves out; its status line rewrites its expiry file,
# and nothing reads it.
# The popup is sized from its content (see picker_size): the list as wide as
# its columns, the preview as wide as the widest pane it can show, capped at
# 90% of the client. `--dry-run` prints the computed widths and opens nothing;
# PICKER_CLIENT_W replaces the client's width.
# A session with no pane found shows "◌ bg <id>" as its tmux session: it runs
# in the background and may still be on screen in one of the "?" panes, when
# the match was ambiguous. Enter does nothing on it.
#
# Keys: Enter jumps to the row's pane. f1..f4 pin the row to that slot
# (only a row with a pane: on a "◌ bg" row the header says so), f12 unpins
# it; the popup stays open and its rows are reloaded.
#
# Internal modes, run by the popup's fzf:
#   --list <dir>                 print the rows (first draw and reload);
#                                cards, widths and scratch files go to <dir>
#   --key <n> <dir> <key> <sid>  print the fzf actions of f<n> on a row
#                                (n is 0 for f12)
# Each row starts with two hidden fields: its key (the pane id, or
# "bg:<short>" for a session without pane) and its session id.

set -eu

dry_run=
[ "${1:-}" = "--dry-run" ] && dry_run=1

. "${0%/*}/picker_lib.sh"
. "${0%/*}/claude_sessions.sh"

TAB=$(printf '\t')

# --key: pin (1-4) or unpin (0) the highlighted row, then reload the rows.
if [ "${1:-}" = --key ]; then
  n=$2 dir=$3 key=$4 sid=$5
  reload="reload('$0' --list '$dir')"
  pins="CLAUDE_PINS_QUIET=1 '${0%/*}/claude_pins.sh'"
  case "$n:$key" in
  0:bg:*) echo "change-header()+execute-silent($pins unpin '$sid')+$reload" ;;
  0:*) echo "change-header()+execute-silent($pins unpin '$key')+$reload" ;;
  *:bg:*) echo "change-header(pin: no pane, can't pin)" ;;
  *) echo "change-header()+execute-silent($pins pin $n '$key')+$reload" ;;
  esac
  exit 0
fi

# build_list <dir>: the formatted rows on stdout, the list and preview widths
# in <dir>/widths, preview cards of background sessions in <dir>/card/, the
# claude_sessions table in <dir>/rows. LIST_OK is empty when `claude agents`
# failed.
build_list() {
  raw="$1/raw"
  rows="$1/rows"
  mkdir -p "$1/card"

  LIST_OK=1
  claude_sessions "$rows" || LIST_OK=

  # Rows are keyed for sorting: Claudes in a pane first, background sessions
  # last; within each by project. The first field is the group digit
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
    # A Claude outside any project is still listed, under its cwd.
    project_root "$abs" || PROJECT_ROOT=$abs
    picker_short_path "$PROJECT_ROOT"
    project=$PICKER_PATH
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
        "$title" "$short" "$session" "$cwd" "$short" >"$1/card/$key"
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$group$state" "$key" "$sess" "$project" "$title" "$cache" "$session" >>"$raw"
  done <"$rows"

  # Pane widths by pane id, for the preview width.
  panew="$1/panew"
  tmux list-panes -a -F "#{pane_id}${TAB}#{pane_width}" >"$panew" 2>/dev/null || : >"$panew"
  # A pane pin only holds for the tmux server it was made on.
  start=$(tmux display-message -p '#{start_time}' 2>/dev/null || true)

  sort -f -t "$TAB" -k1.1,1.1 -k4,4 "$raw" |
    awk -F'\t' -v panew="$panew" -v carddir="$1/card" -v widths="$1/widths" \
      -v pinsdir="$CLAUDE_STATE_DIR/pins" -v start="$start" '
      BEGIN {
        while ((getline line < panew) > 0) {
          split(line, f, "\t")
          pw[f[1]] = f[2]
        }
        # Pins by target: a session id, or a pane id of this tmux server.
        for (n = 1; n <= 4; n++) {
          file = pinsdir "/" n
          if ((getline line < file) > 0) {
            split(line, f, "\t")
            if (f[1] == "session") spin[f[2]] = n
            else if (f[1] == "pane" && f[3] == start) ppin[f[2]] = n
          }
          close(file)
        }
        sw = length("SESSION"); pvw = 0
        tw = length("TITLE"); lw = length("PROJECT")
        # Longest "glyph + space" prefix: one character, or its bytes when awk
        # is not counting in UTF-8.
        glyph = (length("●") == 1) ? 2 : 5
      }
      {
        # Drop the status glyph Claude prefixes its title with.
        if (match($5, /^[^ -~]+ /) && RLENGTH <= glyph) $5 = substr($5, RLENGTH + 1)
        state[NR] = substr($1, 2); id[NR] = $2; sess[NR] = $3; label[NR] = $4; title[NR] = $5; cache[NR] = $6
        sid[NR] = $7
        pin[NR] = ""
        if ($7 != "" && ($7 in spin)) pin[NR] = spin[$7]
        else if ($2 !~ /^bg:/ && ($2 in ppin)) pin[NR] = ppin[$2]
        if (length($5) > tw) tw = length($5)
        if (length($4) > lw) lw = length($4)
        if (length($3) > sw) sw = length($3)
        if ($2 ~ /^bg:/) {
          # A card has no pane: its longest line is the preview width.
          while ((getline line < (carddir "/" $2)) > 0) if (length(line) > pvw) pvw = length(line)
          close(carddir "/" $2)
        } else if (($2 in pw) && pw[$2] + 0 > pvw) pvw = pw[$2] + 0
      }
      END {
        # Column header (fzf --header-lines=1). The dot and the pin digit are
        # centered under theirs.
        printf "-\t-\tSTATE  PIN  CACHE  %-*s  %-*s  %s\n", tw, "TITLE", lw, "PROJECT", "SESSION"
        for (i = 1; i <= NR; i++) {
          color = (state[i] == 0) ? 33 : (state[i] == 1) ? 31 : (state[i] == 2) ? 32 : 90
          dot = (state[i] == 3) ? "?" : "●"
          s = (id[i] ~ /^bg:/) ? "\033[2m" sess[i] "\033[0m" : sess[i]
          p = (pin[i] == "") ? "" : " " pin[i]
          printf "%s\t%s\t  \033[%dm%s\033[0m    %-3s  %-5s  %-*s  %-*s  %s\n",
            id[i], sid[i], color, dot, p, cache[i], tw, title[i], lw, label[i], s
        }
        # Widest list line: the 19 columns before the title, the padded title
        # and project columns with their two-space gaps, and the session column.
        print 19 + tw + 2 + lw + 2 + sw, pvw > widths
      }'
}

if [ "${1:-}" = --list ]; then
  build_list "$2"
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
list="$tmp/list"
sel="$tmp/sel"

build_list "$tmp" >"$list"

if [ ! -s "$tmp/rows" ]; then
  tmux display-message "no claude sessions"
  exit 0
fi

# Drop the expiry and reminder files of sessions that are gone. Skipped when
# `claude agents` failed: every session would look gone. A dry run deletes
# nothing.
if [ -n "$LIST_OK" ] && [ -z "$dry_run" ]; then
  live=" $(cut -d "$CLAUDE_SEP" -f3 "$tmp/rows" | tr '\n' ' ') "
  for f in "$CLAUDE_STATE_DIR"/expiry/* "$CLAUDE_STATE_DIR"/notified/*; do
    [ -f "$f" ] || continue
    case "$live" in
    *" ${f##*/} "*) ;;
    *) rm -f "$f" ;;
    esac
  done
fi

# The popup is sized once, from the first list; reloads keep its size.
read -r list_w preview_w <"$tmp/widths"
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

# f1..f4 and f12 ask --key for their actions; any other key clears the
# message a pin key may have left in the header. --track keeps the cursor at
# its position across a reload; a row appearing or ending in between can move
# it by one.
pin_opts="--track --bind='focus:change-header()' --bind='change:change-header()'"
for n in 1 2 3 4; do
  pin_opts="$pin_opts --bind='f$n:transform:\"$0\" --key $n \"$tmp\" {1} {2}'"
done
pin_opts="$pin_opts --bind='f12:transform:\"$0\" --key 0 \"$tmp\" {1} {2}'"

# The preview captures only the highlighted pane, on demand; a background
# session without pane gets its card instead.
tmux display-popup -E -w "$PICKER_POPUP_W" -h 80% -e "FZF_DEFAULT_OPTS=$PICKER_FZF_OPTS" \
  "fzf --ansi --reverse --header-lines=1 --delimiter='\t' --with-nth=3.. $preview_opts $pin_opts < '$list' > '$sel'" ||
  true

[ -s "$sel" ] || exit 0

pane=$(cut -f1 <"$sel")
case "$pane" in bg:*) exit 0 ;; esac
target=$(tmux display-message -t "$pane" -p '#{session_name}:#{window_index}' 2>/dev/null) || exit 0

tmux switch-client -t "${target%%:*}"
tmux select-window -t "$target"
tmux select-pane -t "$pane"
