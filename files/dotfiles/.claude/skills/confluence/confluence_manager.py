#!/usr/bin/env python3
"""
Confluence Documentation Manager
Manages Confluence pages via REST API with credentials from macOS Keychain
"""

import sys
import json
import argparse
import os
from typing import Optional, Dict, Any
import keyring
from atlassian import Confluence
import markdown


def get_credentials(url: str, username: str) -> Dict[str, str]:
    """Retrieve Confluence credentials from macOS Keychain"""
    # Get API token from keychain
    api_token = keyring.get_password("jira-api-token", os.getenv("USER", "default"))

    if not api_token:
        raise ValueError(
            "API token not found in keychain. Please store it under "
            "service 'jira-api-token' for your user account"
        )

    return {"url": url, "username": username, "api_token": api_token}


def get_confluence_client(url: str, username: str) -> Confluence:
    """Create authenticated Confluence client"""
    creds = get_credentials(url, username)
    return Confluence(
        url=creds["url"],
        username=creds["username"],
        password=creds["api_token"],
        cloud=True
    )


def get_page_by_title(confluence: Confluence, space: str, title: str) -> Optional[Dict[str, Any]]:
    """Get page by space and title"""
    try:
        page = confluence.get_page_by_title(
            space=space,
            title=title,
            expand="body.storage,version"
        )
        return page
    except Exception as e:
        return None


def get_page_by_id(confluence: Confluence, page_id: str) -> Optional[Dict[str, Any]]:
    """Get page by ID"""
    try:
        page = confluence.get_page_by_id(
            page_id=page_id,
            expand="body.storage,version,space"
        )
        return page
    except Exception as e:
        return None


def update_page(
    confluence: Confluence,
    page_id: str,
    content: str,
    title: Optional[str] = None,
    content_format: str = "markdown"
) -> Dict[str, Any]:
    """Update an existing Confluence page"""
    # Get current page to get version number
    page = get_page_by_id(confluence, page_id)
    if not page:
        raise ValueError(f"Page {page_id} not found")

    current_version = page["version"]["number"]
    current_title = page["title"]

    # Convert markdown to Confluence storage format if needed
    if content_format == "markdown":
        html_content = markdown.markdown(content, extensions=['extra', 'codehilite'])
    else:
        html_content = content

    # Update the page
    result = confluence.update_page(
        page_id=page_id,
        title=title or current_title,
        body=html_content,
        version_comment="Updated by Claude Code"
    )

    return result


def create_page(
    confluence: Confluence,
    space: str,
    title: str,
    content: str,
    parent_id: Optional[str] = None,
    content_format: str = "markdown"
) -> Dict[str, Any]:
    """Create a new Confluence page"""
    # Convert markdown to Confluence storage format if needed
    if content_format == "markdown":
        html_content = markdown.markdown(content, extensions=['extra', 'codehilite'])
    else:
        html_content = content

    result = confluence.create_page(
        space=space,
        title=title,
        body=html_content,
        parent_id=parent_id
    )

    return result


def search_pages(confluence: Confluence, query: str, space: Optional[str] = None) -> list:
    """Search for pages by title or content"""
    cql = f'type=page AND title~"{query}"'
    if space:
        cql += f' AND space={space}'

    results = confluence.cql(cql, expand="space,version")
    return results.get("results", [])


def main():
    parser = argparse.ArgumentParser(description="Manage Confluence documentation")

    # Global arguments
    parser.add_argument("--url", required=True, help="Confluence URL (e.g., https://absa.atlassian.net)")
    parser.add_argument("--username", required=True, help="Confluence username/email")

    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Get page command
    get_parser = subparsers.add_parser("get", help="Get page content")
    get_group = get_parser.add_mutually_exclusive_group(required=True)
    get_group.add_argument("--page-id", help="Page ID")
    get_group.add_argument("--title", help="Page title")
    get_parser.add_argument("--space", help="Space key (required with --title)")

    # Update page command
    update_parser = subparsers.add_parser("update", help="Update page content")
    update_parser.add_argument("--page-id", required=True, help="Page ID to update")
    update_parser.add_argument("--content", required=True, help="New content")
    update_parser.add_argument("--title", help="New title (optional)")
    update_parser.add_argument("--format", choices=["markdown", "html"], default="markdown")

    # Create page command
    create_parser = subparsers.add_parser("create", help="Create new page")
    create_parser.add_argument("--space", required=True, help="Space key")
    create_parser.add_argument("--title", required=True, help="Page title")
    create_parser.add_argument("--content", required=True, help="Page content")
    create_parser.add_argument("--parent-id", help="Parent page ID (optional)")
    create_parser.add_argument("--format", choices=["markdown", "html"], default="markdown")

    # Search command
    search_parser = subparsers.add_parser("search", help="Search for pages")
    search_parser.add_argument("--query", required=True, help="Search query")
    search_parser.add_argument("--space", help="Limit to specific space")

    args = parser.parse_args()

    try:
        confluence = get_confluence_client(args.url, args.username)

        if args.command == "get":
            if args.page_id:
                result = get_page_by_id(confluence, args.page_id)
            else:
                if not args.space:
                    print(json.dumps({"error": "--space is required when using --title"}))
                    sys.exit(1)
                result = get_page_by_title(confluence, args.space, args.title)

            if result:
                print(json.dumps({
                    "id": result["id"],
                    "title": result["title"],
                    "space": result.get("space", {}).get("key"),
                    "content": result["body"]["storage"]["value"],
                    "version": result["version"]["number"],
                    "url": f"{args.url}/wiki{result['_links']['webui']}"
                }, indent=2))
            else:
                print(json.dumps({"error": "Page not found"}))
                sys.exit(1)

        elif args.command == "update":
            result = update_page(
                confluence,
                args.page_id,
                args.content,
                args.title,
                args.format
            )
            print(json.dumps({
                "success": True,
                "page_id": result["id"],
                "title": result["title"],
                "version": result["version"]["number"],
                "url": f"{args.url}/wiki{result['_links']['webui']}"
            }, indent=2))

        elif args.command == "create":
            result = create_page(
                confluence,
                args.space,
                args.title,
                args.content,
                args.parent_id,
                args.format
            )
            print(json.dumps({
                "success": True,
                "page_id": result["id"],
                "title": result["title"],
                "space": args.space,
                "url": f"{args.url}/wiki{result['_links']['webui']}"
            }, indent=2))

        elif args.command == "search":
            results = search_pages(confluence, args.query, args.space)
            pages = [{
                "id": r["content"]["id"],
                "title": r["content"]["title"],
                "space": r["content"]["space"]["key"],
                "url": f"{args.url}/wiki{r['content']['_links']['webui']}"
            } for r in results]
            print(json.dumps({"results": pages, "count": len(pages)}, indent=2))

        else:
            parser.print_help()
            sys.exit(1)

    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
