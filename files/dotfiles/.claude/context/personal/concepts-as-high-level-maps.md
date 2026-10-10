---
type: feedback
title: Concepts as high-level maps, not inventories
description: Level of detail for concept files, an orienting overview with pointers rather than a restatement of code.
tags: [okf, context, writing, concepts]
status: stable
generated: { by: claude-code/claude-opus-5-5, at: 2026-10-10T13:43:24Z }
sources:
    - id: tmux-concept-session
      resource: Claude Code conversation in ~/.dot on 2026-10-10 about the tmux-setup concept
      author: human:jakub
---

# Concepts as high-level maps, not inventories

Write a concept as a high-level overview that lets Claude orient itself and then check the real files, not as a document
that explains everything[^tmux-concept-session].

**Why:** the first version of [My tmux setup](/tmux-setup.md) listed every key binding, plugin, threshold and popup key.
I found it full of unnecessary information: things that are not important to Claude (key bindings) and things it can
easily discover by reading the config[^tmux-concept-session].

**How to apply:**

- Keep: the overall model, which parts exist and how they connect, where the details live, and decisions the code does
  not explain.
- Leave out: anything one read of the source file answers (bindings, options, values, per-script behavior).
- Claude's interpretation, not something I stated: a concept that needs editing whenever a small detail of the code
  changes is too detailed.

[^tmux-concept-session]: Claude Code conversation in `~/.dot` on 2026-10-10
