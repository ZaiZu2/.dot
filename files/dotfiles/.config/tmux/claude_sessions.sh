#!/bin/sh
# Sourced by the Claude picker (find_claude.sh), the cache reminder
# (claude_cache_notify.sh) and the pins (claude_pins.sh): one table of every Claude, from `claude agents
# --json` (documented, lists every live session) tied to tmux panes where the
# process tree allows.
#
# claude_sessions <file> writes one row per Claude, fields separated by
# $CLAUDE_SEP (ASCII unit separator: unlike a tab, `read` keeps empty fields
# with it), and returns non-zero when `claude agents` failed (sessions then
# missing from the rows):
#   state    0 waiting on the user, 1 working, 2 idle, 3 unknown
#   pane     tmux pane id (%12), empty when no pane is known
#   session  full session id, empty for a pane no session was tied to
#   short    short id of a background session (claude attach/logs <short>)
#   tmux     tmux session name of the pane
#   title    pane title (glyph Claude prefixes it with included), else the
#            session name
#   cwd      absolute working directory
#   expires  prompt cache expiry in epoch seconds, from the file
#            ~/.claude/statusline.sh keeps per session in
#            $CLAUDE_STATE_DIR/expiry/; empty if unknown
#
# A session is tied to the pane whose shell is an ancestor of its pid: plain
# `claude` sessions. A session moved to the background (← or /background)
# runs in a daemon worker outside any pane; the pane that shows it (agent
# view, `claude attach`) runs only a client. Claude sets that pane's title to
# the session's name, so a client pane is merged with the one background
# session whose name and cwd match its title and cwd, if no other pane or
# session matches too. Otherwise both are listed apart: the session without a
# pane, the pane without a session.
#
# The Q&A Claude's tmux session `_qa` (see claude_qa.sh, tmux.conf) is left
# out: its pane still claims its session, so that it is not listed as one
# without a pane, but no row of `_qa` is written.
#
# All state of the Claude scripts lives under $CLAUDE_STATE_DIR
# ($DOT_STATE_DIR/claude), one subfolder per kind: expiry/ and notified/
# (~/.claude/statusline.sh, which repeats this default), queue/ and
# queue.lock/ (claude_cache_notify.sh), pins/ (claude_pins.sh).

DOT_STATE_DIR="${DOT_STATE_DIR:-${TMPDIR:-/tmp}/dot-state}"
CLAUDE_STATE_DIR="$DOT_STATE_DIR/claude"
CLAUDE_SEP=$(printf '\037')

claude_sessions() {
  _cs_tmp=$(mktemp -d)
  _cs_tab=$(printf '\t')
  # A failing `claude agents` still leaves every Claude pane listed, without
  # session; the status says so, for callers that prune by session.
  _cs_ok=0
  if claude agents --json >"$_cs_tmp/json" 2>/dev/null; then
    jq -r '.[] | [.sessionId // "", .id // "", .kind, (.pid // "" | tostring),
      .status // "", .state // "", .name // "", .cwd] | @tsv' \
      <"$_cs_tmp/json" >"$_cs_tmp/sessions" 2>/dev/null || _cs_ok=1
  else
    _cs_ok=1
  fi
  [ "$_cs_ok" = 0 ] || : >"$_cs_tmp/sessions"
  tmux list-panes -a -F "#{pane_id}${_cs_tab}#{pane_pid}${_cs_tab}#{session_name}${_cs_tab}#{pane_current_command}${_cs_tab}#{pane_current_path}${_cs_tab}#{pane_title}" \
    >"$_cs_tmp/panes" 2>/dev/null || : >"$_cs_tmp/panes"
  ps -A -o pid=,ppid= >"$_cs_tmp/ps" 2>/dev/null || : >"$_cs_tmp/ps"

  awk -F'\t' -v OFS="$CLAUDE_SEP" -v expiry_dir="$CLAUDE_STATE_DIR/expiry" '
    BEGIN {
      # Longest "glyph + space" prefix: one character, or its bytes when awk
      # is not counting in UTF-8.
      glyph = (length("●") == 1) ? 2 : 5
    }
    function bare(t) {
      # Drop the status glyph Claude prefixes its title with.
      if (match(t, /^[^ -~]+ /) && RLENGTH <= glyph) return substr(t, RLENGTH + 1)
      return t
    }
    function expiry(sid,   file, line, w) {
      if (sid == "") return ""
      file = expiry_dir "/" sid
      line = ""
      if ((getline line < file) > 0) { close(file); split(line, w, " "); return w[1] }
      return ""
    }
    function state_of(status, state) {
      if (status == "waiting") return 0
      if (status == "busy") return 1
      if (status == "idle") return 2
      if (state == "blocked") return 0
      return 3
    }
    FILENAME == ARGV[1] { split($0, w, " "); parent[w[1]] = w[2]; next }
    FILENAME == ARGV[2] {
      np++; pid_of[np] = $1; shell[$2] = np
      tsess[np] = $3; cmd[np] = $4; pcwd[np] = $5; ptitle[np] = $6
      next
    }
    {
      # Walk up from the session pid to the first pane shell, if any.
      at = ""
      for (p = $4; p != "" && p > 1 && !(p in shell); p = parent[p]) if (++hops > 64) break
      hops = 0
      if (p in shell) at = shell[p]
      st = state_of($5, $6)
      if (at != "") {
        claimed[at] = 1
        # Claimed above, so the Q&A session is not listed as one without a pane.
        if (tsess[at] == "_qa") next
        title = (ptitle[at] != "") ? ptitle[at] : $7
        print st, pid_of[at], $1, $2, tsess[at], title, pcwd[at], expiry($1)
      } else {
        nb++; bst[nb] = st; bsid[nb] = $1; bshort[nb] = $2; bname[nb] = $7; bcwd[nb] = $8
        if ($7 != "") skeys[$8 SUBSEP $7]++
      }
    }
    END {
      # Panes of `_qa` are skipped too, so its Claude is not listed as a pane without a session.
      for (i = 1; i <= np; i++)
        if (!(i in claimed) && tsess[i] != "_qa" && (cmd[i] == "claude" || cmd[i] == "claude.exe")) {
          client[i] = 1
          k = pcwd[i] SUBSEP bare(ptitle[i])
          pkeys[k]++; pane_at[k] = i
        }
      for (j = 1; j <= nb; j++) {
        k = bcwd[j] SUBSEP bname[j]
        if (bname[j] != "" && skeys[k] == 1 && pkeys[k] == 1) {
          i = pane_at[k]; delete client[i]
          print bst[j], pid_of[i], bsid[j], bshort[j], tsess[i], ptitle[i], pcwd[i], expiry(bsid[j])
        } else {
          print bst[j], "", bsid[j], bshort[j], "", bname[j], bcwd[j], expiry(bsid[j])
        }
      }
      for (i = 1; i <= np; i++)
        if (i in client) print 3, pid_of[i], "", "", tsess[i], ptitle[i], pcwd[i], ""
    }' "$_cs_tmp/ps" "$_cs_tmp/panes" "$_cs_tmp/sessions" >"$1"

  rm -rf "$_cs_tmp"
  return "$_cs_ok"
}
