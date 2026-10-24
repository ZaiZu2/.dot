---
type: reference
title: Caller-scoped permission gates
description: >-
    My design for gating a sensitive Claude Code action: a `PreToolUse` hook that asks by default, lifted per caller
    by a launch env var or the calling subagent's `agent_type`, with the commit gate as its example.
tags: [claude-code, permissions, hooks, agents, design]
status: stable
generated: { by: claude-code/claude-opus-5-5, at: 2026-10-24T10:25:36Z }
sources:
    - id: hook
      resource: ~/.dot/files/dotfiles/.claude/hooks/commit-gate.sh
      title: commit-gate.sh, the PreToolUse hook and its header comment
      author: human:jakub
    - id: probes
      resource: Claude Code conversation in ~/.dot on 2026-10-16, headless `claude -p` permission probes
      author: human:jakub
    - id: request
      resource: Claude Code conversation in ~/.dot on 2026-10-24
      author: human:jakub
---

# Caller-scoped permission gates

A gate makes a sensitive action ask me by default and lets chosen callers run it unasked. The permission is injected
from outside the session, never granted by the model: by whoever launches `claude` (an env var), or by which subagent
makes the call (its `agent_type`). I want new gates built this way[^request].

## How it works

- **Allow in settings, ask in a hook.** `settings.json` allows the command, with no `ask` rule for it. A `PreToolUse`
  hook with the matching tool matcher asks: it prints `permissionDecision: "ask"` with a reason that names the env var,
  and exits 0 silently when the call isn't gated or the caller may run it.
- **Match the whole command line.** Also catch the action after `;`, `&`, `|`, `(` and behind wrappers such as `git -C`,
  so `cd x && <action>` is gated too.
- **Session-wide: a launch env var**, `CLAUDE_ALLOW_<ACTION>`: `1` for every agent of the session, or a comma list of
  extra agent types. Set only when launching `claude`.
- **Per caller: a name-only agent**, `<action>-agent`, with no `model` and no `tools`, which the hook always allows by
  the `agent_type` field of its input. A forked skill that should run the action unattended sets `context: fork` and
  `agent: <action>-agent`, and picks its own `model`.

## Why it is built this way

Found with headless probes on the commit gate[^probes]:

- An `ask` rule beats every `allow`, whatever its source: a skill's `allowed-tools`, an agent, a `--settings` file. So
  the ask has to live in a hook to be lifted per caller.
- `--setting-sources` without `user` drops user-level skills and agents too, so it can't replace the user settings.
- An env var can't be set for one subagent: the whole session shares the process env. The hook input carries
  `agent_type` for subagents (absent in the main session), which is how one agent is told apart.
- An `env` value in `settings.json` overrides the same var set at launch. The env var must stay out of
  `settings.json`, which is why the always-allowed agent is built into the hook rather than listed in the var.
- A model's own "ran / denied" answer is unreliable, and it may refuse the action for other reasons (a CLAUDE.md rule).
  Test a gate by reading `permission_denials` from `claude -p --output-format json`.

## Example: the commit gate

- `settings.json` allows `Bash(git commit -m *)`; `~/.claude/hooks/commit-gate.sh` asks before every `git commit`. The
  values and matching rules are in its header comment[^hook].
- The always-allowed agent is `commit-agent` (`~/.claude/agents/commit-agent.md`); `/feature` forks into it.
- The env var is `CLAUDE_ALLOW_COMMIT`. The zsh function `gC` (`.zshrc_aliases`) runs `/commit` headless with
  `CLAUDE_ALLOW_COMMIT=1`.

[^hook]: `~/.dot/files/dotfiles/.claude/hooks/commit-gate.sh`

[^probes]: Claude Code conversation in `~/.dot` on 2026-10-16

[^request]: Claude Code conversation in `~/.dot` on 2026-10-24
