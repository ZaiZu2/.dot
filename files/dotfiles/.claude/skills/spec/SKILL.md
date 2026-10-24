---
name: spec
description: '[hitl] Plan a new feature through a critical, codebase-informed interview and produce a spec.'
disable-model-invocation: true
---

# Feature Spec

Turn a rough feature idea into an unambiguous spec by interviewing the user and checking their answers against the code.
The goal is a correct, complete plan, not agreement: find gaps, wrong assumptions and conflicts with the code before
anything is built. The only file you write is the spec.

## Target

The feature described in the request; if there is none, ask for one. Restate it in 2-3 sentences and point out what's
ambiguous.

The result is a spec at `<repo root>/.claude/features/<feature-slug>/spec.md` (unless the user names another path), in the
layout and rules of `${CLAUDE_SKILL_DIR}/brief.md`; read it first, since each step gathers what fills it. `/scope` later
writes part files beside the spec.

## Actions

### 1. Investigate

Before the first question, read (not infer from file names), for every repository the feature touches:

- the affected code (entry points, data models, APIs, config), patterns of similar features, and anything that already
  does part of this or conflicts with it;
- constraints: `AGENTS.md` or `CLAUDE.md`, docs, TODOs, recent `git log` of the area; library behavior via Context7;
- its main checkout (first entry of `git worktree list`) and test suite command (from `AGENTS.md`/`CLAUDE.md`, else CI,
  else `Makefile`; the local equivalent if CI runs elsewhere).

Use an Explore subagent on large codebases. Share brief findings (`path:line`, patterns, early concerns).

### 2. Interview

Three phases, big picture first. Close each phase before the next; if a later answer reopens an earlier phase, return
to it.

1. **Requirements**: goal, scope (in and out), user-facing behavior and contract, edge cases and failure modes, and a
   validation criterion for each requirement: an observable result that proves it is met, not "works" or "looks
   right". Nothing about how it's built.
2. **Architecture**: approach and alternatives, components and repositories involved and their responsibilities, data
   flow, contracts between them (interfaces, file formats, names), new dependencies.
3. **Details**: concrete changes per component (files, functions, data, error handling, config), and delivery:
   - PR merge order across repositories, and each PR's base (the default branch unless the user names another);
   - what can be built in parallel: only a need for another change's code makes work sequential; a contract the spec
     pins down doesn't, nor does merge order;
   - how each criterion is checked, per repository: take the user's word (manual, or little automation), plus whatever
     runs unattended (test suite, CI command); don't push for more;
   - Jira, only if the user raises it: the issue, and whether to implement under it, update it or add children. Read its
     type and children first: a Task takes only Sub-tasks, a Sub-task none.

Skip a topic only when the code or earlier answers settle it, and say so. Skip process topics (stakeholders, metrics,
rollout, timelines).

- One question at a time, broad to specific, as plain text (not `AskUserQuestion`), with your recommended option first.
- Ground questions in the code ("`submit()` at `orders/service.py:88` retries without idempotency keys; must the webhook
  be idempotent?"), not generic prompts ("what about retries?").
- Never assume. What the code settles beyond doubt is recorded as found; ask about everything else, including what the
  code only suggests. Follow up on any answer open to interpretation.
- Challenge every answer: contradictions with the code or earlier answers, hidden consequences (broken callers,
  migrations, invariants), missed cases, vague terms ("fast"), gold-plating, reinventing what exists. Tag issues
  `[BLOCKER]`, `[CONCERN]` or `[NIT]` with evidence, and read the code before objecting. Concede when wrong; skip nits
  that wouldn't change the design.
- If the user insists without addressing an issue, explain once more, then record it as an accepted risk; never drop it.

Keep resolved points in one numbered list the user can refer to ("revisit 7"):

- `<n>. [decided|found|risk] <point>: <reason or evidence>`; `found` is settled by the code, `risk` an accepted risk.
- Number in order of resolution, across phases, never renumbering: a changed point is marked `(revised)`, a dropped one
  `(dropped)`.
- Open questions are listed as `Q1`, `Q2`, ...; a resolved one becomes the next numbered point.

After each phase, show the points it added or changed, and the open questions.

### 3. Confirm

Stop when no question is open, nothing in scope reads two ways, every requirement has a validation criterion, and a
subagent could implement it without basic questions. Then:

- Check values that go stale (versions, tags, latest release) against the base branch, not memory or an older spec.
- Check each base exists on `origin` with no unpushed local commits (`git rev-list --count origin/<base>..<base>` is
  `0`); otherwise tell the user to push them before `/feature`.
- Run each test suite in the base's checkout if it's clean; otherwise skip and say so. Without asking, record a test
  that already fails as a known failure under its repository in `Base repositories`, with its cause from `git log`;
  don't fix it or deselect it.

Show the full numbered list and get confirmation.

### 4. Write the spec

Don't overwrite an existing spec without asking. Delivery goes in `Base repositories`, even for one repository;
`Requirements` hold behavior only.

A spec with a `Parts` section was already split by `/scope`, and `/feature` builds from its part files. Before editing
it, say so, name the parts affected, and ask whether to go on. Never edit part files or `Parts`; rerunning `/scope`
syncs them.

## Report

Give the spec's path and the accepted risks by number, and tell the user to run `/scope <spec path>`; for an already
split spec, say its parts are now out of date and that this updates them.
