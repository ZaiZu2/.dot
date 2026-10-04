#!/bin/sh
# Claude Code hook: print the index of every OKF context bundle that applies to the session.
#
# Wired into settings.json:
#   SessionStart -> context-index.sh
#
# Bundles, in order:
#   personal  ~/.claude/context/personal    (tracked in the dot repo)
#   mounted   ~/.claude/context/<prefix>    (symlinks created by `dot claude context`)
#   project   <project root>/.claude/context
#
# Stdout is added to the session context. Each bundle is printed under a heading naming its root, so the relative
# links of its index can be resolved. A bundle without index.md gets one synthesized from concept frontmatter.
# Always exits 0 so a broken bundle never blocks Claude.

set -u

ROOT="$HOME/.claude/context"
PERSONAL="$ROOT/personal"
# Claude passes the hook JSON on stdin; skip it when run by hand from a terminal, where cat would wait forever
INPUT=''
[ -t 0 ] || INPUT=$(cat 2>/dev/null || true)
SEEN=''

# Physical path of a directory, empty when it does not exist
resolve() {
  (cd -P "$1" 2>/dev/null && pwd -P) || true
}

project_dir() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"
    return
  fi
  if [ -n "$INPUT" ] && command -v jq >/dev/null 2>&1; then
    cwd=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)
    if [ -n "$cwd" ]; then
      printf '%s' "$cwd"
      return
    fi
  fi
  pwd
}

# Index body without the okf_version frontmatter
print_index() {
  awk 'NR == 1 && /^---[[:space:]]*$/ { fm = 1; next }
       fm && /^---[[:space:]]*$/ { fm = 0; next }
       !fm' "$1"
}

# One line per concept, built from its title/description frontmatter
synthesize_index() {
  find -L "$1" -name '*.md' ! -name index.md ! -name log.md 2>/dev/null | sort | while IFS= read -r file; do
    awk -v path="${file#"$1"/}" '
      function value(line) { sub(/^[a-z]+:[[:space:]]*/, "", line); gsub(/^["\047]|["\047]$/, "", line); return line }
      NR == 1 && /^---[[:space:]]*$/ { fm = 1; next }
      fm && /^---[[:space:]]*$/ { exit }
      fm && /^title:/ { title = value($0) }
      fm && /^description:/ { desc = value($0) }
      END {
        if (title == "") title = path
        printf "* [%s](%s)%s\n", title, path, (desc == "" ? "" : " - " desc)
      }' "$file"
  done
}

# emit <kind> <root>: print one bundle, once
emit() {
  root=$(resolve "$2")
  [ -n "$root" ] || return 0
  case "$SEEN" in
  *"|$root|"*) return 0 ;;
  esac
  SEEN="$SEEN|$root|"

  if [ -f "$2/index.md" ]; then
    body=$(print_index "$2/index.md")
  else
    body=$(synthesize_index "$2")
  fi
  [ -n "$body" ] || return 0

  if [ -z "${HEADER_DONE:-}" ]; then
    printf '# Context bundles (OKF 0.2)\n\n'
    printf 'Links are relative to the root of their bundle. Read a concept when its line is relevant to the task.\n'
    HEADER_DONE=1
  fi
  printf '\n## %s bundle: %s\n\n%s\n' "$1" "$2" "$body"
}

emit personal "$PERSONAL"

# The personal bundle is linked file by file, so the dot repo directory behind it is the same bundle; its parent
# only holds bundles and is not a project bundle either
if [ -L "$PERSONAL/index.md" ]; then
  source_root=$(resolve "$(dirname "$(readlink "$PERSONAL/index.md")")")
  [ -n "$source_root" ] && SEEN="$SEEN|$source_root|${source_root%/*}|"
fi

for mount in "$ROOT"/*; do
  [ -d "$mount" ] || continue
  emit "${mount##*/}" "$mount"
done

emit project "$(project_dir)/.claude/context"

exit 0
