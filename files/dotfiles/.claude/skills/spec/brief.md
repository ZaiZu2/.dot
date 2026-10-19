# Brief layout

The layout of a work brief: a spec file written by `spec`, and a part file written by `scope`. A brief must stand
alone for an implementer (the user, a fresh session or a subagent) who has no other context.

- Include only what was decided or found, and omit empty sections.
- Keep requirements concrete, and reference code with `path:line`.
- The `Base repositories` and `Parts` sections are for a spec file. `Parts` is added by `scope` and read by `feature`.
- When the spec spans several repositories, name the repository with every file reference and every change.
- `Verification` is required, and every requirement is covered by at least one entry. An entry names the check and its
  expected result, concrete enough to pass or fail without judgment. A check the user does by hand is marked
  `(manual)`; `feature` runs the other entries and leaves those to the user.

A spec file is `.claude/spec/<feature>/spec.md`, and its part files sit beside it. A part file is
`.claude/spec/<feature>/<no>_<name>.md`: `<feature>` is the name of the spec's directory, `<no>` a two-digit number
counted across the whole spec in the order the parts can be built, `<name>` one or two kebab-case words. Its id is
`<feature>/<no>`, and its title `# <no>: <what it covers>`. It names its repository in `Summary`, and the parts it comes
after go under `Notes`.

```markdown
# <Feature name>

## Summary

<2-3 sentences: what changes and why.>

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

- <command or check> → <expected result> (requirements <n>, ...)

## Notes

<Accepted risks, dependencies on other work.>

## Base repositories

<The starting points `scope` distributes the work from; its `Parts` blocks hold the final values.>

- `<name>`: `<absolute path of the main checkout>`, base `<branch the PR targets>`, test suite `<command>` or `none`
  - Known failure on the base: `<test id>`: <cause, with the commit that introduced it>

<One line per repository, in the order its PRs must merge. The first is where the spec lives.>

- **Parallel**: <which changes can be built at the same time, or `all`>
- **Sequential**: <change> after <change>: <the code it needs>, or `none`

- **Jira**: [<KEY>](https://absa.atlassian.net/browse/<KEY>) (<issue type>), <implement under it | update it | extend
  it>

<Only when the user wants Jira issues under an existing one.>

## Parts

- **Jira**: [<KEY>](https://absa.atlassian.net/browse/<KEY>)

<Only when `scope` wrote Jira issues: the parent issue.>

### <repository>

<One block per repository, in the order of `Base repositories`. Every value is final: `feature` uses it as written.>

- **Checkout**: `<absolute path of the main checkout>`
- **Base**: `<branch the PR targets>`
- **Branch**: `<slug>`, or `<PARENT-KEY>-<slug>` with a Jira parent (`<slug>`: the short 2-3-word kebab-case description
  `scope` picked, not the spec's file name)
- **Worktree**: `<checkout>/<branch>` (created by `scope`; the `feature` session runs in it)
- **Test suite**: `<command>`, or `none` (its parts' `Verification` stands in)
- **Parts**, in dependency order:
  1. `<feature>/<no>`: `<absolute path of the part file>`: <what it covers> <`(after <feature>/<no>, ...)` when it
     needs the code of other parts, of any repository> <`(files: <paths>)`, the files it changes>
     <`(Jira: [<KEY>](https://absa.atlassian.net/browse/<KEY>))`, the issue that covers it>
```
