---
type: feedback
title: Ask about the plan before implementing a feature
description: Presenting the planned design of a new feature and asking about its open choices before writing any code.
tags: [workflow, planning, features, claude-code]
status: stable
generated: { by: claude-code/claude-opus-5-5, at: 2026-10-10T12:41:18Z }
sources:
    - id: cache-reminder-session
      resource: Claude Code conversation in ~/.dot on 2026-10-10 about a tmux reminder for the expiring Claude prompt cache
      author: human:jakub
---

# Ask about the plan before implementing a feature

When I ask for a new feature, first tell me what you plan to implement and ask me about the open design choices. Start
writing code only after I have answered[^cache-reminder-session].

**Why:** I said "I'd like to create a feature - tmux reminder when the claude cache is running out". Claude built the
whole thing with its own defaults, including a transient tmux status-bar message as the reminder. That form turned out
not to be useful to me, and I asked: "can you first ask me about what you plan to implement then just implementing
it?"[^cache-reminder-session].

**How to apply:**

- Before implementing, outline the plan briefly and ask about the choices that shape the result: how it surfaces to me,
  when it triggers, what it covers.
- Reading code and investigating beforehand is fine; it makes the questions better.
- Claude's interpretation, not something I stated: this is about features with real design choices, not about small
  fixes or edits where the request already determines the outcome.

[^cache-reminder-session]: Claude Code conversation in `~/.dot` on 2026-10-10
