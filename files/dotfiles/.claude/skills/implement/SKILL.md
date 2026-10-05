---
name: implement
description:
    '[auto] Implement a ticket, spec or described change in the code. Use when the user asks to implement a specific
    Jira ticket or spec file.'
---

# Implement

Turn a brief into working code. A good result does what the brief says and nothing more, reads like the code around it,
and passes the brief's verification. Never commit, push, or write to Jira or a PR.

This skill runs either in the main session or in a subagent that was told to follow this file, so when a brief is named,
take everything from it and not from the conversation.

## Target

What the request names:

- a Jira key: read the issue with the `mcp__atlassian__*` tools on `absa.atlassian.net`; its description is the brief;
- a spec file: the brief is the whole spec, or the part the request names;
- a change described in the request or the conversation.

If the request names a directory, work there: `cd` into it first, as a command of its own. Stop and reply only with the reason if nothing
identifies the work, the ticket can't be read, or the brief doesn't say what to change or how to tell it is done.

## Actions

### 1. Read the brief

Note the scope (in and out), the files and symbols it names, the edge cases, the verification, and the tickets it
depends on.

### 2. Read the code

Read every file the brief names and the code it calls, plus the closest existing example of the same kind of change
(naming, layering, error handling). For a library whose API you aren't sure of, look up its docs with the
`mcp__context7__*` tools when they are available.

### 3. Implement

Make the change with the smallest diff that satisfies the brief. Handle each edge case the brief lists.

### 4. Verify

Run the brief's verification. Fix failures caused by your change and rerun, for at most 3 rounds. If it still fails, or
the failure comes from code outside the brief, stop fixing and report it.

### 5. Document

Call the Skill tool with `doc`, naming the files you changed. If the Skill tool is unavailable, read
`${CLAUDE_SKILL_DIR}/../doc/SKILL.md` and apply its rules yourself. Rerun the verification afterwards.

## Rules

- Change only what the brief covers. If it turns out to need a change outside its scope, or the brief contradicts the
  code, report that instead of widening the work.
- Where the brief and the project's conventions differ on style, the project wins.
- Write tests only when the brief asks for them, following `${CLAUDE_SKILL_DIR}/../test/SKILL.md`.
- Never weaken a check or a test to make the verification pass.
- No refactoring, renaming or reformatting of code the brief doesn't touch.

## Report

List the files changed with what changed in each, the output of the final verification run, every deviation from the
brief with its reason, the open issues, and the assumptions made.
