---
title: Confluence Documentation Manager
description: Create and update Confluence documentation pages directly from Claude
permissions:
  - bash
---

# Confluence Documentation Manager

This skill enables Claude to create and update Confluence documentation pages.

## Capabilities

- **Update Documentation Pages**: Update existing Confluence pages with new content
- **Create Documentation Pages**: Create new Confluence pages in specified spaces
- **Get Page Content**: Retrieve current content from Confluence pages
- **Search Pages**: Find pages by title or space

## Usage Examples

### Update Existing Documentation
"Update the Confluence page 'SFTP Configuration Guide' with the new authentication steps"

"Update page ID 123456 with this content: [content here]"

### Create New Documentation
"Create a new Confluence page in the TECH space titled 'SSH Key Management'"

### View Current Content
"Show me the current content of the Confluence page 'API Documentation'"

## Requirements

### User Setup (one-time)

**Store API Token in Keychain**:
```bash
# Save API token to keychain
security add-generic-password -s "jira-api-token" -a "$USER" -w "YOUR_API_TOKEN_HERE"

# Verify API token is stored (this will print the token)
security find-generic-password -s "jira-api-token" -a "$USER" -w
```

## Configuration

Confluence instance details:
- **URL**: `https://absa.atlassian.net`
- **Username**: `jakub.kawecki@absa.africa`

## Implementation

Uses the shared Python environment at `~/.claude/skills/.venv` to execute `confluence_manager.py`. The script:
- Retrieves API token from macOS Keychain (service: `jira-api-token`)
- Accepts URL and username as command-line arguments

Example commands:
```bash
# Get page by ID
~/.claude/skills/.venv/bin/python ~/.claude/skills/jira/confluence_manager.py \
  --url https://absa.atlassian.net \
  --username jakub.kawecki@absa.africa \
  get --page-id 123456

# Update page
~/.claude/skills/.venv/bin/python ~/.claude/skills/jira/confluence_manager.py \
  --url https://absa.atlassian.net \
  --username jakub.kawecki@absa.africa \
  update --page-id 123456 --content "New content here"

# Create page
~/.claude/skills/.venv/bin/python ~/.claude/skills/jira/confluence_manager.py \
  --url https://absa.atlassian.net \
  --username jakub.kawecki@absa.africa \
  create --space TECH --title "New Page" --content "Page content"

# Search pages
~/.claude/skills/.venv/bin/python ~/.claude/skills/jira/confluence_manager.py \
  --url https://absa.atlassian.net \
  --username jakub.kawecki@absa.africa \
  search --query "SFTP" --space TECH
```

**Note:** All skills now share a common Python environment managed at `~/.claude/skills/`. Dependencies are defined in `~/.claude/skills/pyproject.toml`.
