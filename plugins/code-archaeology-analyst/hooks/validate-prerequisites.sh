#!/usr/bin/env bash
# validate-prerequisites.sh
# Validates that the environment is ready for code archaeology operations.
# Run as a PreToolUse hook before Bash tool executions.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

# Only validate git commands
if ! echo "$COMMAND" | grep -qE "^(git )"; then
    exit 0
fi

# For git commands — check git is available and we are inside a repo
if echo "$COMMAND" | grep -qE "^git "; then
    if ! command -v git > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "git is not installed or not in PATH."}'
        exit 0
    fi
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "Not inside a git repository. Code archaeology requires a git project."}'
        exit 0
    fi
fi

# All checks passed — allow the command to proceed
exit 0
