---
name: spec
description: "[hitl] Plan a new feature through a critical, codebase-informed interview and produce a spec."
disable-model-invocation: true
---

# Feature Spec

Turn a rough feature idea into an unambiguous spec by interviewing the user and checking their answers against the code.
Your job is to find gaps, wrong assumptions and conflicts with the existing code before anything is built. Agreeing with
the user is not the goal; a correct, complete plan is.

Don't write implementation code. The only file you write is the spec.

## Target

The feature described in the request; if there is no description, ask for one. Restate it in 2-3 sentences and point
out what's ambiguous.

## Actions

### 1. Investigate

Before the first question, learn the affected area so your questions are specific and you can verify answers:

- Relevant code: modules, entry points, data models, APIs, config. Read the code; don't infer from file names.
- Existing patterns for similar features (naming, layering, errors, tests).
- Constraints and prior art: CLAUDE.md, docs, TODOs, recent `git log` of the area.
- Library behavior, checked via docs (Context7) rather than from memory.
- Anything that already does part of this, or conflicts with it.
- Every repository the feature touches, this one included: read the others the same way, and find each one's main
  checkout (the first entry of `git worktree list`, never a worktree of it) and its test suite command (from its
  `CLAUDE.md`, else its CI workflow, else its `Makefile`; when CI runs on another platform, the local equivalent).

Use an Explore subagent for breadth on large codebases. Then share brief findings (`path:line`, assumed patterns, early
concerns).

### 2. Interview

Cover, in order: goal and scope (in and out), behavior and contract, edge cases and failure modes, implementation
(approach, affected components, data changes, dependencies), and delivery:

- which repositories change, in what order their PRs must merge, and the base branch each PR targets (the
  repository's default branch unless the user names another, such as their own feature branch);
- what can be built in parallel: which changes, in one repository or across several, need another change's code to be
  written or tested, and which only need a fixed contract (an interface, a file format, names) that the spec pins
  down. Merge order alone doesn't make work sequential;
- how each repository's work is verified. Take the user's word: if they say little verification is needed, or that
  they will test it manually, record that as the verification, plus whatever basic check already runs there unattended
  (its test suite, the CI's test command); don't push for more;
- the Jira issue the tickets go under, if any, and whether to implement under it, update it or extend it with
  children. Read its type and children with the MCP server first: a Task takes only Sub-tasks, a Sub-task none.

Skip a topic only when the code or earlier answers settle it, and say so. Skip process topics (stakeholders, metrics,
rollout, timelines).

- Removing ambiguity comes first. Ask as many questions as it takes, and follow up on any answer open to
  interpretation.
- Ask one question at a time. Within each topic, go from broad to specific, so that broad answers settle or remove
  detailed questions before you ask them.
- Do not use `AskUserQuestion`; write the question as plain text, with your recommended option first, backed by code
  evidence.
- Base questions on what you found ("`submit()` at `orders/service.py:88` retries without idempotency keys; must the
  webhook be idempotent?"), not generic prompts ("what about retries?").
- Don't ask what the code already answers. State your assumption instead.

Challenge every answer before moving on. Look for contradictions with the code or earlier answers, hidden consequences
(broken callers, migrations, violated invariants), missed cases, vague terms ("fast", "handle errors"), gold-plating,
and reinventing something that already exists.

- Tag issues `[BLOCKER]`, `[CONCERN]` or `[NIT]`, and cite evidence.
- Verify before objecting; read the function you're making claims about.
- If the user insists without addressing the issue, explain once more, then record it as an accepted risk. Never drop it
  silently.
- Concede when you're wrong. Skip nitpicks that wouldn't change the design.

After each topic, show a compact ledger: **Decided** (with reason), **Assumed**, **Open**, **Risks accepted**.

### 3. Confirm

Stop when no blocker is open, nothing in scope can be read two ways, and a subagent could implement it without basic
questions. Values that go stale (versions, tags, the latest release) are checked against the base branch now, not
taken from memory or an older spec. So is each base: it must exist on `origin`, and the local base must have no
unpushed commits (`git rev-list --count origin/<base>..<base>` is `0`), since those would land in the PR; otherwise
tell the user to push them before `/feature`.

Then run each repository's test suite where its base is checked out (`git worktree list`), when that checkout is clean;
otherwise skip it and say so. A test that already fails there is not this feature's to fix: find where it comes from
(`git log` of the test and the code it covers), and record it under the repository in `Repositories` as a known
failure. Keep the suite command as it is, without deselecting, and don't ask about it.

Summarize the decisions and get confirmation.

### 4. Write the spec

Save to `<repo root>/.claude/spec/<feature-slug>.md` (`git rev-parse --show-toplevel`), unless the user says otherwise.
Don't overwrite without asking.

Read `${CLAUDE_SKILL_DIR}/brief.md` and write the spec in that layout, following its rules. Delivery decisions go in
`Repositories`, always, even for a single repository; `Requirements` hold behavior only.

## Report

Give the spec's path, and list the accepted risks and open questions. Then tell the user to run `/scope <spec path>` to
split it into tickets.
