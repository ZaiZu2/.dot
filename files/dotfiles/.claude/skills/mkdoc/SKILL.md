---
name: mkdoc
description:
    "[auto] Write markdown documentation for a specified part of a project (module, tool, config, workflow), matching
    the project's existing doc style."
context: fork
model: sonnet
---

# Project Documentation

Write documentation that reads as native to the project, and covers only behavior visible in the code.

## Target

Document only what the request names: a module, tool, config system, workflow, or a section of an existing doc. If the
request names no target, stop and reply only that the part to document must be specified.

## Actions

### 1. Infer style

Find existing docs (`.md`/`.rst` in the root, `docs/`, `doc/`, `wiki/`, `.github/`) and read 2-3 representative ones.
Note tone, tense and voice, header casing and depth, what gets backticked or bolded, code-block language tags, list
markers, how warnings are written, and which sections recur. Follow that style. With no existing docs, use present
tense, title-case headers, backticks for code and `-` bullets.

### 2. Read the code

Read the relevant source, config examples and CLI entry points. Establish what the target does and where it fits, its
configuration (env vars, files, defaults), its CLI (commands, flags), and how it runs (cron, daemon, manual).

Comments that ask for something to be documented (`# add to docstring`, `# document this`, `# mention in docs`) are
input: include what they ask for, then delete those comments from the source. Leave other comments alone.

### 3. Choose location

Use the path from the request. Otherwise put the file where the project's docs live, or `README.md` at the root if
there are none.

### 4. Write

Match the structure from step 1. Never replace an existing file the request didn't name: add to it with Edit, or, if it
covers something else, write a new file next to it and say so. No YAML frontmatter unless the existing docs use it.
Prefer prose where it flows better than bullets.

## Report

Say what was written where, list the sections, and name any source comments you removed.
