---
type: feedback
title: Coding rules
description: >-
    My rules for code written for me: the structure of code comments and keyword-argument notation when constructing
    models and dataclasses by hand.
tags: [coding-style, comments, python]
status: stable
generated: { by: claude-code/claude-sonnet-5-5, at: 2026-10-30T10:12:42Z }
sources:
    - id: ps-reporting-review
      resource: Claude Code conversation in ps-reporting (fix/FAPE-1593-copy-hook-chmod) on 2026-10-22/23
      title: My corrections to the comments and code written during the `CreateDirs` refactor
      author: human:jakub
---

# Comments

A comment argues for a design choice:

- **State the choice and why** it is done this way. No what-ifs about alternative implementations or what to switch to
  if things change.
- **Name the cost** the choice causes and why it is accepted, e.g. "This leaks a config validation model into the domain
  objects - accepted for a single source of the parsing and validation rules."
- **Be exact about behaviour.** Say which parts are inherited or overridden and which value wins. Never over-generalise
  (e.g. "created regardless of the ZIP file's value" when its mode is still inherited).
- **Keep it minimal.** Don't restate what the code does.

# Constructing models

Build models and dataclasses by hand with every field as an explicit keyword argument, e.g.
`CreateDirs(enabled=True, mode=DEFAULT_MODE)`, not `CreateDirs()` or `CreateDirs(mode=...)`.

Always fill a dataclass in kwarg notation, never positionally: `Point(x=1, y=2)`, not `Point(1, 2)`. This holds for
every dataclass, including one with a single field.
