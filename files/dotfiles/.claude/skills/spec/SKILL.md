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

Use an Explore subagent for breadth on large codebases. Then share brief findings (`path:line`, assumed patterns, early
concerns).

### 2. Interview

Cover, in order: goal and scope (in and out), behavior and contract, edge cases and failure modes, implementation
(approach, affected components, data changes, dependencies). Skip a topic only when the code or earlier answers settle
it, and say so. Skip process topics (stakeholders, metrics, rollout, timelines).

- Removing ambiguity comes first. Ask as many questions as it takes, and follow up on any answer open to
  interpretation.
- Ask one question at a time. Within each topic, go from broad to specific, so that broad answers settle or remove
  detailed questions before you ask them.
- Use `AskUserQuestion` for discrete choices, with your recommended option first, backed by code evidence.
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
questions. Summarize the decisions and get confirmation.

### 4. Write the spec

Save to `<repo root>/.claude/spec/<feature-slug>.md` (`git rev-parse --show-toplevel`), unless the user says otherwise.
Don't overwrite without asking.

Read `${CLAUDE_SKILL_DIR}/brief.md` and write the spec in that layout, following its rules.

## Report

Give the spec's path, and list the accepted risks and open questions.
