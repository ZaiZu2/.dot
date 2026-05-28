#!/usr/bin/env python3
"""
JIRA Ticket Manager
Manages JIRA issues via REST API with credentials from macOS Keychain
"""

import sys
import json
import argparse
import os
from typing import Optional

import keyring
from atlassian import Jira


def get_credentials(url: str, username: str) -> dict:
    """Retrieve JIRA credentials from macOS Keychain"""
    api_token = keyring.get_password("jira-api-token", os.getenv("USER", "default"))

    if not api_token:
        raise ValueError(
            "API token not found in keychain. Please store it under "
            "service 'jira-api-token' for your user account"
        )

    return {"url": url, "username": username, "api_token": api_token}


def get_jira_client(url: str, username: str) -> Jira:
    """Create authenticated JIRA client"""
    creds = get_credentials(url, username)
    return Jira(
        url=creds["url"],
        username=creds["username"],
        password=creds["api_token"],
        cloud=True,
    )


def create_issue(
    jira: Jira,
    project: str,
    summary: str,
    issue_type: str = "Task",
    priority: str = "Medium",
    description: Optional[str] = None,
    assignee: Optional[str] = None,
    labels: Optional[list] = None,
) -> dict:
    """Create a new JIRA issue"""
    fields = {
        "project": {"key": project},
        "summary": summary,
        "issuetype": {"name": issue_type},
        "priority": {"name": priority},
    }

    if description:
        fields["description"] = description
    if assignee:
        fields["assignee"] = {"accountId": assignee}
    if labels:
        fields["labels"] = labels

    result = jira.create_issue(fields)
    return result


def get_issue(jira: Jira, key: str) -> dict:
    """Get issue details by key"""
    issue = jira.issue(key, expand="transitions")
    return issue


def search_issues(jira: Jira, jql: str, max_results: int = 50) -> list:
    """Search for issues using JQL"""
    results = jira.jql(jql, limit=max_results)
    return results.get("issues", [])


def add_comment(jira: Jira, key: str, body: str) -> dict:
    """Add a comment to an issue"""
    result = jira.issue_add_comment(key, body)
    return result


def transition_issue(jira: Jira, key: str, status: str) -> dict:
    """Transition an issue to a new status"""
    # Get available transitions
    transitions = jira.get_issue_transitions(key)
    target = None
    for t in transitions:
        if t["name"].lower() == status.lower():
            target = t
            break

    if not target:
        available = [t["name"] for t in transitions]
        raise ValueError(
            f"Transition '{status}' not available. Available: {', '.join(available)}"
        )

    jira.set_issue_status(key, target["name"])
    return {"key": key, "status": target["name"]}


def update_issue(
    jira: Jira,
    key: str,
    summary: Optional[str] = None,
    description: Optional[str] = None,
    priority: Optional[str] = None,
    assignee: Optional[str] = None,
    labels: Optional[list] = None,
) -> dict:
    """Update fields on an existing issue"""
    fields = {}
    if summary:
        fields["summary"] = summary
    if description:
        fields["description"] = description
    if priority:
        fields["priority"] = {"name": priority}
    if assignee:
        fields["assignee"] = {"accountId": assignee}
    if labels:
        fields["labels"] = labels

    if not fields:
        raise ValueError("No fields to update")

    jira.update_issue_field(key, fields)
    return {"key": key, "updated_fields": list(fields.keys())}


def format_issue(issue: dict, url: str) -> dict:
    """Format issue for output"""
    fields = issue.get("fields", {})
    return {
        "key": issue["key"],
        "summary": fields.get("summary"),
        "status": fields.get("status", {}).get("name"),
        "priority": fields.get("priority", {}).get("name"),
        "assignee": (fields.get("assignee") or {}).get("displayName"),
        "type": fields.get("issuetype", {}).get("name"),
        "labels": fields.get("labels", []),
        "description": fields.get("description"),
        "created": fields.get("created"),
        "updated": fields.get("updated"),
        "url": f"{url}/browse/{issue['key']}",
    }


def main():
    parser = argparse.ArgumentParser(description="Manage JIRA tickets")

    parser.add_argument("--url", required=True, help="JIRA URL")
    parser.add_argument("--username", required=True, help="JIRA username/email")

    subparsers = parser.add_subparsers(dest="command", help="Command to execute")

    # Create issue
    create_parser = subparsers.add_parser("create", help="Create a new issue")
    create_parser.add_argument("--project", required=True, help="Project key (e.g. FAPE)")
    create_parser.add_argument("--summary", required=True, help="Issue summary")
    create_parser.add_argument("--type", default="Task", help="Issue type (default: Task)")
    create_parser.add_argument("--priority", default="Medium", help="Priority (default: Medium)")
    create_parser.add_argument("--description", help="Issue description")
    create_parser.add_argument("--assignee", default="712020:8e7a54c5-a95d-4d2e-be17-7a7a6348c4e4", help="Assignee account ID (default: Jakub Kawecki)")
    create_parser.add_argument("--labels", help="Comma-separated labels")

    # Get issue
    get_parser = subparsers.add_parser("get", help="Get issue details")
    get_parser.add_argument("--key", required=True, help="Issue key (e.g. FAPE-1293)")

    # Search issues
    search_parser = subparsers.add_parser("search", help="Search issues with JQL")
    search_parser.add_argument("--jql", required=True, help="JQL query")
    search_parser.add_argument("--max-results", type=int, default=50, help="Max results")

    # Add comment
    comment_parser = subparsers.add_parser("comment", help="Add comment to issue")
    comment_parser.add_argument("--key", required=True, help="Issue key")
    comment_parser.add_argument("--body", required=True, help="Comment text")

    # Transition issue
    transition_parser = subparsers.add_parser("transition", help="Transition issue status")
    transition_parser.add_argument("--key", required=True, help="Issue key")
    transition_parser.add_argument("--status", required=True, help="Target status name")

    # Update issue
    update_parser = subparsers.add_parser("update", help="Update issue fields")
    update_parser.add_argument("--key", required=True, help="Issue key")
    update_parser.add_argument("--summary", help="New summary")
    update_parser.add_argument("--description", help="New description")
    update_parser.add_argument("--priority", help="New priority")
    update_parser.add_argument("--assignee", help="New assignee account ID")
    update_parser.add_argument("--labels", help="Comma-separated labels")

    args = parser.parse_args()

    try:
        jira = get_jira_client(args.url, args.username)

        if args.command == "create":
            labels = args.labels.split(",") if args.labels else None
            result = create_issue(
                jira,
                args.project,
                args.summary,
                args.type,
                args.priority,
                args.description,
                args.assignee,
                labels,
            )
            print(json.dumps({
                "success": True,
                "key": result["key"],
                "url": f"{args.url}/browse/{result['key']}",
            }, indent=2))

        elif args.command == "get":
            issue = get_issue(jira, args.key)
            print(json.dumps(format_issue(issue, args.url), indent=2))

        elif args.command == "search":
            issues = search_issues(jira, args.jql, args.max_results)
            formatted = [format_issue(i, args.url) for i in issues]
            print(json.dumps({"results": formatted, "count": len(formatted)}, indent=2))

        elif args.command == "comment":
            result = add_comment(jira, args.key, args.body)
            print(json.dumps({
                "success": True,
                "key": args.key,
                "comment_id": result.get("id"),
            }, indent=2))

        elif args.command == "transition":
            result = transition_issue(jira, args.key, args.status)
            print(json.dumps({"success": True, **result}, indent=2))

        elif args.command == "update":
            labels = args.labels.split(",") if args.labels else None
            result = update_issue(
                jira,
                args.key,
                args.summary,
                args.description,
                args.priority,
                args.assignee,
                labels,
            )
            print(json.dumps({"success": True, **result}, indent=2))

        else:
            parser.print_help()
            sys.exit(1)

    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
