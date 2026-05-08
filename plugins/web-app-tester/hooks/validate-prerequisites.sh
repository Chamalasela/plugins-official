#!/usr/bin/env bash
# validate-prerequisites.sh
# Validates that the environment is ready for web-app-tester operations.
# Run as a PreToolUse hook before Bash tool executions.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

# Check npx is available (required for the bundled Playwright MCP server)
if ! command -v npx > /dev/null 2>&1; then
    echo '{"decision": "block", "reason": "npx is not installed or not in PATH. Node.js 18+ is required to run the bundled Playwright MCP server. Install Node.js from https://nodejs.org — see docs/mcp-config.md"}'
    exit 0
fi

# Only validate gh commands beyond this point
if ! echo "$COMMAND" | grep -qE "^gh "; then
    exit 0
fi

# Check gh CLI is installed
if ! command -v gh > /dev/null 2>&1; then
    echo '{"decision": "block", "reason": "GitHub CLI (gh) is not installed or not in PATH. Install it: brew install gh (macOS), winget install GitHub.cli (Windows), or apt install gh (Linux). See docs/mcp-config.md"}'
    exit 0
fi

# Check gh is authenticated (or GITHUB_TOKEN is set)
if ! timeout 10s gh auth status > /dev/null 2>&1; then
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        echo '{"decision": "block", "reason": "gh CLI is not authenticated and GITHUB_TOKEN is not set. Run: gh auth login — or export GITHUB_TOKEN=ghp_xxx. See docs/mcp-config.md"}'
        exit 0
    fi
fi

# All checks passed — allow the command to proceed
exit 0
