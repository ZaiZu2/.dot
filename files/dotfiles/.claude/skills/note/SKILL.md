---
title: Zettelkasten Note Generator
description: Generate markdown notes from conversation context and save them to your ZK notebook
permissions:
  - bash
---

# Zettelkasten Note Generator

This skill enables Claude to create structured markdown notes based on the current conversation context and save them to your Zettelkasten notebook using the `zk` command.

## Capabilities

- **Summarize Conversations**: Extract key insights from the current conversation
- **Generate Markdown Notes**: Create well-structured notes with proper formatting
- **Save to ZK**: Automatically save notes to your notebook at `$ZK_NOTEBOOK_DIR`
- **Smart Titles**: Generate appropriate note titles based on content

## Usage Examples

### Basic Note Creation
"Create a note about the Pyramid thread-local pattern we just discussed"

"Take a note summarizing the GIL and threading conversation"

### With Custom Title
"Note this as 'Python GIL and Web Servers'"

### Code-Focused Notes
"Create a note documenting the PrimeConnector class we looked at"

## How It Works

When you invoke `/note [topic]`, Claude will:

1. **Analyze Context**: Review the current conversation to extract relevant information
2. **Generate Content**: Create a well-structured markdown note including:
   - Clear title and optional tags
   - Summary of key points
   - Code examples (if applicable)
   - References to files discussed
   - Any insights or conclusions
3. **Save with zk**: Use `zk new` to create the note in your notebook
4. **Confirm**: Show you the note path and content

## Note Structure

Generated notes follow this structure:

```markdown
# [Title]

## Summary
[Brief overview of the topic]

## Key Points
- Point 1
- Point 2
- Point 3

## Details
[Detailed explanation, code examples, etc.]

## References
- [File paths, links, related concepts]

## Tags
#tag1 #tag2
```

## Implementation

The skill uses the `zk new` command with these key options:
- `--interactive` or `-i`: Read content from stdin
- `--title` or `-t`: Set the note title
- `--print-path` or `-p`: Print the note path instead of opening editor
- `--extra`: Pass variables to template (e.g., `tags="python,web"`)
- `--group` or `-g`: Use a specific group configuration (optional)

Example commands:
```bash
# Create note with content piped from stdin
echo "Note content here" | zk new -i -p --title "My Note" --extra tags="python,web"

# Or using heredoc
zk new -i -p --title "Python GIL and Threading" --extra tags="python,gil" <<'EOF'
# Content

Summary here...
EOF
```

## Configuration

**Prerequisites:**
- `zk` command installed (Homebrew: `brew install zk`)
- `$ZK_NOTEBOOK_DIR` environment variable set
- ZK notebook initialized at that location

**Verify setup:**
```bash
echo $ZK_NOTEBOOK_DIR  # Should print: /Users/AB0383Q/Notes
zk list --limit 5       # Should list recent notes
```

## Instructions for Claude

When this skill is invoked:

1. **Extract the topic**: Determine what aspect of the conversation to note
   - If user specifies: Use their topic
   - If not specified: Analyze the conversation and choose the most relevant topic

2. **Generate note content**:
   - Write clear, informative markdown content
   - **DO NOT include YAML frontmatter** (title/tags) - the template handles this
   - Start directly with markdown headings and content
   - Include code snippets with proper formatting (use triple backticks with language)
   - Reference file paths using absolute paths when relevant
   - Keep it concise but comprehensive
   - Use standard markdown: headings (#), lists (-), code blocks (```), etc.

3. **Determine tags**:
   - Generate 2-5 relevant tags based on the content
   - Common categories: language (python, javascript), domain (web, cli, dsa), patterns (threading, async)
   - Format as comma-separated: `python,threading,web`

4. **Create the note**:
   ```bash
   zk new -i -p --title "Your Generated Title" --extra tags="tag1,tag2,tag3" <<'EOF'
   # Main Heading

   Content here...

   ## Section

   More content...
   EOF
   ```
   - Use `--interactive` (`-i`) to read from stdin
   - Use `--print-path` (`-p`) to print path instead of opening editor
   - Pass tags via `--extra tags="..."`
   - Content should be plain markdown (no frontmatter)

5. **Confirm to user**:
   - Show the note title and tags
   - Display a preview of the content (first few lines or key sections)
   - Show the file path where it was saved
   - Confirm success

**Important:**
- Generate meaningful titles (not generic like "Note 1" or "Untitled")
- The zk template will add frontmatter automatically
- Only write the markdown body content
- Use proper markdown formatting
- Content should be useful standalone (someone finding this note later should understand it)
