# Brief layout

The layout of a work brief: a spec file written by `spec`, and a ticket description written by `scope`. A brief must
stand alone for an implementer (the user, a fresh session or a subagent) who has no other context.

- Include only what was decided, assumed or found, and omit empty sections.
- Keep requirements concrete, and reference code with `path:line`.
- The `#` title and the `Repositories` and `Tickets` sections are for a spec file; a ticket has its summary field
  instead. `Tickets` is added by `scope` and read by `feature`.
- When the spec spans several repositories, name the repository with every file reference and every change.
- A `Verification` entry may be a check the user does by hand; mark it `(manual)`. `feature` runs the other entries and
  leaves those to the user.

```markdown
# <Feature name>

## Summary

<2-3 sentences: what changes and why.>

## Repositories

- `<name>`: `<absolute path of the main checkout>`, base `<branch the PR targets>`, test suite `<command>` or `none`
  - Known failure on the base: `<test id>`: <cause, with the commit that introduced it>

<One line per repository, in the order its PRs must merge. The first is where the spec lives.>

- **Parallel**: <which changes can be built at the same time, or `all`>
- **Sequential**: <change> after <change>: <the code it needs>, or `none`

- **Jira**: [<KEY>](https://absa.atlassian.net/browse/<KEY>) (<issue type>), <implement under it | update it | extend
  it>

<Only when the tickets go under an existing issue.>

## Context

<How the affected area works today, with file references. Patterns and constraints to follow.>

## Scope

- **In**: ...
- **Out**: ...

## Requirements

1. ...

## Edge Cases

- <case> → <expected behavior>

## Implementation

- **Approach**: ...
- **Changes**: `path/to/file` → what changes
- **Rejected alternatives**: <option> → why

## Verification

- <command or check that proves it is done>

## Notes

<Accepted risks, assumptions, open questions, dependencies on other work.>

## Tickets

- **Parent**: [<KEY>](https://absa.atlassian.net/browse/<KEY>)

### <repository>

<One block per repository, in the order of `Repositories`. Every value is final: `feature` uses it as written.>

- **Checkout**: `<absolute path of the main checkout>`
- **Base**: `<branch the PR targets>`
- **Branch**: `<PARENT-KEY>-<slug>`
- **Worktree**: `<checkout>/<branch>`
- **Test suite**: `<command>`, or `none` (its leaves' `Verification` stands in)
- **Leaves**, in dependency order:
  1. [<KEY>](https://absa.atlassian.net/browse/<KEY>): <what it covers> <`(brief: spec)` when the issue's own
     description isn't a brief> <`(after <KEY>, ...)` when it needs the code of other leaves, of any repository>
     <`(files: <paths>)`, the files it changes>
```
