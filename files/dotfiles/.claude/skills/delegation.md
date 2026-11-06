# Inline or Delegated

A skill without `context: fork` loads in the agent that invoked it. Its `Where it runs` section says when to delegate;
apply this to it:

- **In a subagent** (started by the Agent tool or a forked skill), or where no Agent tool exists (Copilot CLI): run the
  skill's steps yourself, never start another agent.
- **In the main session** (the conversation with the user), when the skill's condition holds: don't run the steps
  yourself. Start one Agent (general-purpose, with the model the skill names) told to read
  `~/.claude/skills/<name>/SKILL.md` and follow it for the request, which you pass verbatim with the absolute path of
  the directory to work in. It can't see the conversation, so add nothing from it. Return its report as your result.
- **In the main session**, when it doesn't hold: run the steps yourself.
