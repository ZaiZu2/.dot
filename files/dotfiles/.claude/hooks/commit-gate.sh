#!/bin/sh
# Claude Code PreToolUse hook (matcher Bash): ask before every git commit, unless
# the caller may commit unasked. settings.json allows `git commit -m *`, so this
# hook is the only thing that asks.
#
# Always allowed: the commit-agent subagent (hook input `agent_type`; the main
# session has none). CLAUDE_ALLOW_COMMIT, set when launching claude, adds more:
#   1     every agent of the session
#   a,b   these agent types too
# Don't set it in settings.json `env`: that overrides the launch value.

set -eu

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

printf '%s' "$cmd" | grep -qE '(^|[;&|(][[:space:]]*)git( -C [^ ]+)? commit( |$)' || exit 0

allow="${CLAUDE_ALLOW_COMMIT:-}"
[ "$allow" = 1 ] && exit 0

agent=$(printf '%s' "$input" | jq -r '.agent_type // empty')
if [ -n "$agent" ]; then
  case ",commit-agent,$allow," in
    *",$agent,"*) exit 0 ;;
  esac
fi

printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"git commit needs approval (CLAUDE_ALLOW_COMMIT)"}}'
