---
type: project
title: Claude pins across /clear
description: >-
    Open design item for the Claude pins: keeping a session pin when `/clear` gives the pinned Claude a new session id,
    with a SessionEnd/SessionStart hook preferred over pid matching.
tags: [tmux, claude-code, claude-pins, hooks, open-question]
status: draft
generated: { by: claude-code/claude-sonnet-5-5, at: 2026-10-24T12:50:32Z }
stale_after: 2026-12-01T00:00:00Z
sources:
    - id: pr3
      resource: https://github.com/ZaiZu2/.dot/pull/3
      title: PR #3, Claude pins
      author: human:jakub
    - id: review
      resource: ../features/claude-pins/review.md
      title: PR #3 review report, finding 1
    - id: transcripts
      resource: ~/.claude/projects/-home-jakub--dot/
      title: Claude Code transcripts that start with /clear (2b688ddb…, 04f6b5a8…, 0ce779f0…)
    - id: hooks-docs
      resource: https://code.claude.com/docs/en/hooks
      title: Claude Code hooks reference
---

# Problem

A session pin (`pins/<n>`, written by `claude_pins.sh`) is keyed by the Claude session id. `/clear` keeps the same Claude
process in the same pane but starts a new transcript with a new session id.[^transcripts] `claude agents --json` lists
sessions by that id, so the next `M-n` reports `pin <n>: <title> is gone` and clears the slot.[^review] The spec's
edge cases cover a Claude that exits and a new `claude` in the pane, not `/clear`.

Unconfirmed: that `claude agents --json` shows the new id at once and drops the old one. Check: pin a Claude, run
`/clear` in it, press `M-n`.

# Preferred fix: a hook

On `/clear`, Claude Code fires `SessionEnd` with `reason: "clear"` (old `session_id`) and `SessionStart` with
`source: "clear"` (new `session_id`), both from the same Claude process.[^hooks-docs] One script in
`files/dotfiles/.claude/hooks/` links them through the Claude pid, found by walking its own parent chain:

1. `SessionEnd` writes the old id to `$CLAUDE_STATE_DIR/cleared/<claude pid>`.
2. `SessionStart` reads that file, rewrites every `pins/<n>` holding the old id to the new id (slot and title kept),
   then deletes the file.

It leaves the pin format, the `claude_sessions.sh` rows and the picker unchanged and uses only documented hooks. It
adds the script, `SessionEnd` and `SessionStart` entries in `settings.json` (today only `Notification` and
`PreToolUse`), and updates to the tmux-setup concept and requirement 1 of the spec.

Confirm before building: the field names and that `SessionEnd` fires before `SessionStart`; that the hook process
descends from the Claude pid, also for a background session. Test: a throwaway hook that logs its stdin and parent
chain on both events, then one `/clear`.

# Rejected alternative: pid matching

Store the Claude pid in a session pin and re-key a pin whose id is no longer listed to the live session with the same
pid. It changes the `claude_sessions.sh` row format, which shifts what `find_claude.sh` and `claude_cache_notify.sh`
read as their last field, and the pid may change when a background session is reattached with `claude attach`.

# Open question

Should a pin also follow `/resume` inside a running Claude (`SessionStart` with `source: "resume"`)? Recommendation:
no, since `/resume` loads a different conversation.

# Status

Not implemented. To revisit once PR #3 has been tested by hand.[^pr3]

[^transcripts]: Claude Code transcripts that start with /clear
[^review]: PR #3 review report, finding 1
[^hooks-docs]: Claude Code hooks reference
[^pr3]: PR #3, Claude pins
