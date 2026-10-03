---
name: confluence
description: "[hitl] Get, search, create and update Confluence pages through the Atlassian MCP server."
model: sonnet
disable-model-invocation: true
---

# Confluence

Read and write Confluence pages on `https://absa.atlassian.net` with the Confluence tools of the `atlassian` MCP server
(`mcp__atlassian__*`). A good result is a page that reads as before plus the requested change, with nothing lost.

## Target

The page or space the request names. Ask for missing required values (space, title, page) rather than guessing.

## Tools

- Pick the tool by its description; tool names change between server versions, so don't rely on remembered ones.
- Pass `absa.atlassian.net` where a tool asks for the site, or resolve its cloud ID with the server's
  accessible-resources tool first. Never work on another site, even if the account can reach one.
- If no `atlassian` tools are available, stop and tell the user to run `dot claude mcp`, then `/mcp` to sign in.

## Actions

Reads and searches end after step 1.

### 1. Find the page

Resolve a page by title with a search when the user gives no ID. If several pages match, ask which one.

### 2. Prepare the content

- An update replaces the whole page body. Fetch the page first and merge your changes into its current content; keep
  the title unless asked to change it.
- If the fetched body holds macros or markup the write format can't express, say so before updating instead of dropping
  them.
- Write in the format the tool's body field asks for (Markdown unless it says otherwise).

### 3. Confirm

Show the title, target (space/parent or page) and content, and wait for approval. Pages are shared, so never write
without it.

### 4. Write

Create or update the page.

## Report

Page title and URL after a write, a title/space/URL table for searches.
