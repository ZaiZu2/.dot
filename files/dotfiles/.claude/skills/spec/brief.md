# Brief layout

The layout of a work brief: a spec file written by `spec`, and a ticket description written by `feature`. A brief must
stand alone for an implementer (the user, a fresh session or a subagent) who has no other context.

- Include only what was decided, assumed or found, and omit empty sections.
- Keep requirements concrete, and reference code with `path:line`.
- The `#` title is for a spec file; a ticket has its summary field instead.

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

- <command or check that proves it is done>

## Notes

<Accepted risks, assumptions, open questions, dependencies on other work.>
```
