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

# Check knowledge file exists
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$0")/..}"
KNOWLEDGE_FILE="${PLUGIN_ROOT}/knowledge/chatbot-tester.json"
if [ ! -f "$KNOWLEDGE_FILE" ]; then
    echo "{\"decision\": \"block\", \"reason\": \"Knowledge file not found at ${KNOWLEDGE_FILE}. Copy knowledge/chatbot-tester.example.json to knowledge/chatbot-tester.json and fill in your widget hints and Q&A pairs — see docs/setup.md\"}"
    exit 0
fi

# Check widget block exists in knowledge file
if ! python3 -c "import json,sys; d=json.load(open('${KNOWLEDGE_FILE}')); sys.exit(0 if 'widget' in d else 1)" 2>/dev/null; then
    echo '{"decision": "block", "reason": "The knowledge file is missing a `widget` block. Add widget.trigger_hint, widget.ready_hint, and widget.response_done_hint in plain language — see docs/setup.md"}'
    exit 0
fi

# Detect platform from git remote
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if echo "$REMOTE_URL" | grep -q "github.com"; then
    PLATFORM="GitHub"
elif echo "$REMOTE_URL" | grep -qE "dev\.azure\.com|visualstudio\.com"; then
    PLATFORM="AzureDevOps"
else
    PLATFORM="Unknown"
fi

# --- GitHub platform checks ---
if [ "$PLATFORM" = "GitHub" ]; then
    if ! echo "$COMMAND" | grep -qE "^gh "; then
        exit 0
    fi

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

# --- Azure DevOps platform checks ---
if [ "$PLATFORM" = "AzureDevOps" ]; then
    if ! echo "$COMMAND" | grep -qE "^curl "; then
        exit 0
    fi

    if ! command -v curl > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "curl is not installed or not in PATH. curl is required for Azure DevOps API calls."}'
        exit 0
    fi

    if [ -z "${AZURE-DEVOPS-TOKEN:-}" ]; then
        echo '{"decision": "block", "reason": "AZURE-DEVOPS-TOKEN is not set. Create a Personal Access Token in Azure DevOps and export AZURE-DEVOPS-TOKEN=your_pat — see docs/setup.md"}'
        exit 0
    fi
fi

exit 0
