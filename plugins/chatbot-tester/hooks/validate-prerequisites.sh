#!/usr/bin/env bash
# validate-prerequisites.sh
# Validates that the environment is ready for chatbot-tester operations.
# Run as a PreToolUse hook before Bash tool executions.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

# Check Python 3.10+ is available
if ! command -v python3 > /dev/null 2>&1; then
    echo '{"decision": "block", "reason": "python3 is not installed or not in PATH. Python 3.10+ is required to run Playwright tests. Install Python from https://python.org — see docs/setup.md"}'
    exit 0
fi

PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.major * 100 + sys.version_info.minor)" 2>/dev/null || echo "0")
if [ "$PYTHON_MINOR" -lt 310 ]; then
    echo '{"decision": "block", "reason": "Python 3.10+ is required but an older version was found. Upgrade Python — see docs/setup.md"}'
    exit 0
fi

# Check playwright Python package is available
if ! python3 -c "import playwright" > /dev/null 2>&1; then
    echo '{"decision": "block", "reason": "The playwright Python package is not installed. Run: pip install playwright && playwright install chromium — see docs/setup.md"}'
    exit 0
fi

# GitHub CLI checks — only when a gh command is about to run
if echo "$COMMAND" | grep -qE "^gh "; then
    if ! command -v gh > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "GitHub CLI (gh) is not installed or not in PATH. Install it: brew install gh (macOS), winget install GitHub.cli (Windows), or apt install gh (Linux)."}'
        exit 0
    fi

    if ! timeout 10s gh auth status > /dev/null 2>&1; then
        if [ -z "${GITHUB_TOKEN:-}" ]; then
            echo '{"decision": "block", "reason": "gh CLI is not authenticated and GITHUB_TOKEN is not set. Run: gh auth login — or export GITHUB_TOKEN=ghp_xxx."}'
            exit 0
        fi
    fi
fi

# Azure DevOps checks — only when a curl command is about to run
if echo "$COMMAND" | grep -qE "^curl "; then
    if ! command -v curl > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "curl is not installed or not in PATH. curl is required for Azure DevOps API calls."}'
        exit 0
    fi

    if [ -z "${AZURE_DEVOPS_TOKEN:-}" ]; then
        echo '{"decision": "block", "reason": "AZURE_DEVOPS_TOKEN is not set. Create a Personal Access Token in Azure DevOps and set AZURE_DEVOPS_TOKEN=your_pat — see docs/setup.md"}'
        exit 0
    fi
fi

exit 0
