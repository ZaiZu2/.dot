---
name: note
description: "[auto] Write a markdown note from the current conversation and save it to a zk notebook."
model: sonnet
---

# Zettelkasten Note

Turn the conversation into a standalone note and save it with `zk`. Someone finding the note later must understand it
without the conversation.

## Content

- Topic: what the request names; otherwise the conversation's main subject.
- A specific title, never generic ("Python GIL and Threading", not "Note 1").
- Markdown body only. No frontmatter; the zk template adds it.
- Suggested structure: Summary, Key Points, Details (code with language-tagged blocks), References (absolute file
  paths, links). Drop sections that don't fit.
- 2-5 tags: language, domain, pattern (e.g. `python`, `web`, `threading`).

## Notebooks

| Notebook | Env var | Use for |
|----------|---------|---------|
| Personal | `$ZK_NOTEBOOK_DIR` | Default |
| Work | `$ZK_ABSA_DIR` | Work topics, or hints like "absa note", "zka", "work note" |

Personal: pipe the body in, comma-separated tags.

```bash
zk new -i -p --title "<title>" --extra tags="python,threading" <<'EOF'
# Heading
...
EOF
```

Work: its template drops piped content, and tags are space-separated. Create the note, then append the body.

```bash
NOTE_PATH=$(cd "$ZK_ABSA_DIR" && ZK_NOTEBOOK_DIR="$ZK_ABSA_DIR" zk new -p --title "<title>" --extra tags="front-arena runbook")
cat >> "$NOTE_PATH" <<'EOF'

# Heading
...
EOF
```

## Report

Show the title, tags, saved path and a short preview.
