# Global CLAUDE settings

## General

- NEVER commit anything to GIT by yourself, even when explicitly asked. Any commits can only be done by ME, the user.
- When a Bash command (or set of commands) is denied by the permission system, do NOT silently retry with a variant. Stop, tell the user what was denied, and ASK whether to proceed — the denial may be an intentional safeguard rather than a permission-list gap. Only re-invoke the same action after the user confirms in-conversation.
- NEVER add emojis to any generated artifact (PR bodies, PR titles, commit messages, code, docs, file contents).

## Skill setup

See `~/.claude/skills/README.md` for the full skills setup, directory structure, and instructions for
adding/updating/removing skills.

## MCPs

Below rules define when each listed MCP should be used.

### Context7

Up-to-date Code Docs - Context7 MCP pulls up-to-date, version-specific documentation and code examples straight from the
source — and places them directly into your prompt.

Always use context7 when answering questions about API, interfaces or internal workings of a given library. This means
you should automatically use the Context7 MCP tools to resolve library id and get library docs without me having to
explicitly ask.

@RTK.md
