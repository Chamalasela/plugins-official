#!/usr/bin/env bash
# validate-prerequisites.sh
# Validates that the environment is ready for dependency optimization operations.
# Run as a PreToolUse hook before Bash tool executions.
#
# Credentials
#   GITHUB-TOKEN         — used by git push for HTTPS auth (GitHub)
#   AZURE-DEVOPS-TOKEN   — used by git push and curl for Azure DevOps

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")

# ─── GitHub CLI ───────────────────────────────────────────────────────────────
# gh is only valid against github.com remotes — block it on all other platforms.

if echo "$COMMAND" | grep -qE "(^|[[:space:]])gh[[:space:]]"; then
    if ! command -v gh > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "GitHub CLI (gh) is not installed or not in PATH. Install: https://cli.github.com — see docs/platform-setup.md"}'
        exit 0
    fi
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo '{"decision": "block", "reason": "Not inside a git repository. gh commands require a checked-out repo."}'
        exit 0
    fi

    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ] && ! echo "$REMOTE_URL" | grep -q "github.com"; then
        if echo "$REMOTE_URL" | grep -qE "(dev\.azure\.com|visualstudio\.com)"; then
            echo '{"decision": "block", "reason": "gh CLI is for GitHub remotes only — this remote is Azure DevOps. Use curl + AZURE-DEVOPS-TOKEN per providers/azure-devops.md."}'
        elif echo "$REMOTE_URL" | grep -q "bitbucket.org"; then
            echo '{"decision": "block", "reason": "gh CLI is for GitHub remotes only — this remote is Bitbucket. Write the report to dependency-optimization-report.md per providers/generic.md."}'
        else
            echo '{"decision": "block", "reason": "gh CLI is for GitHub remotes only — this remote is not GitHub. Write the report to dependency-optimization-report.md per providers/generic.md."}'
        fi
        exit 0
    fi

    exit 0
fi

# ─── Azure DevOps REST (curl) ──────────────────────────────────────────────────

if echo "$COMMAND" | grep -qE "curl.*(dev\.azure\.com|visualstudio\.com|app\.vssps\.visualstudio\.com)"; then
    if [ -z "${AZURE-DEVOPS-TOKEN:-}" ]; then
        if env | grep -q '^AZURE-DEVOPS-TOKEN='; then
            echo '{"decision": "block", "reason": "Found AZURE-DEVOPS-TOKEN (with hyphens) but it cannot be referenced as a bash variable. Re-export as: export AZURE_DEVOPS_TOKEN=$(env | sed -n s/^AZURE-DEVOPS-TOKEN=//p)"}'
        else
            echo '{"decision": "block", "reason": "AZURE-DEVOPS-TOKEN is not set. Pass it at runtime: AZURE-DEVOPS-TOKEN=<pat> claude ... (see docs/platform-setup.md)"}'
        fi
        exit 0
    fi
    exit 0
fi

# ─── Package manager audit tools ──────────────────────────────────────────────
# Warn (but do not block) if an audit tool is called but not installed.
# The agents have fallback behaviour, so these are warnings, not hard blocks.

_warn_missing() {
    echo '{"decision": "warn", "reason": "'"$1"'"}'
}

if echo "$COMMAND" | grep -qE "(^|[[:space:]])npm audit"; then
    if ! command -v npm > /dev/null 2>&1; then
        _warn_missing "npm is not installed. Vulnerability scan will fall back to manifest-only analysis."
    fi
    exit 0
fi

if echo "$COMMAND" | grep -qE "(^|[[:space:]])pip-audit"; then
    if ! command -v pip-audit > /dev/null 2>&1; then
        _warn_missing "pip-audit is not installed. Install: pip install pip-audit. Falling back to manifest analysis."
    fi
    exit 0
fi

if echo "$COMMAND" | grep -qE "(^|[[:space:]])cargo audit"; then
    if ! command -v cargo-audit > /dev/null 2>&1; then
        _warn_missing "cargo-audit is not installed. Install: cargo install cargo-audit. Falling back to cargo metadata analysis."
    fi
    exit 0
fi

if echo "$COMMAND" | grep -qE "(^|[[:space:]])govulncheck"; then
    if ! command -v govulncheck > /dev/null 2>&1; then
        _warn_missing "govulncheck is not installed. Install: go install golang.org/x/vuln/cmd/govulncheck@latest. Falling back to go list analysis."
    fi
    exit 0
fi

if echo "$COMMAND" | grep -qE "(^|[[:space:]])license-checker"; then
    if ! command -v license-checker > /dev/null 2>&1; then
        _warn_missing "license-checker is not installed. Install: npm install -g license-checker. Falling back to package.json license field scan."
    fi
    exit 0
fi

if echo "$COMMAND" | grep -qE "(^|[[:space:]])pip-licenses"; then
    if ! command -v pip-licenses > /dev/null 2>&1; then
        _warn_missing "pip-licenses is not installed. Install: pip install pip-licenses. Falling back to pip show metadata."
    fi
    exit 0
fi

if echo "$COMMAND" | grep -qE "(^|[[:space:]])depcheck"; then
    if ! command -v depcheck > /dev/null 2>&1; then
        _warn_missing "depcheck is not installed. Install: npm install -g depcheck. Falling back to grep-based import scan."
    fi
    exit 0
fi

# ─── git ──────────────────────────────────────────────────────────────────────

if ! echo "$COMMAND" | grep -qE "^git "; then
    exit 0
fi

if ! command -v git > /dev/null 2>&1; then
    echo '{"decision": "block", "reason": "git is not installed or not in PATH."}'
    exit 0
fi

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo '{"decision": "block", "reason": "Not inside a git repository. Dependency optimization requires a git project."}'
    exit 0
fi

if echo "$COMMAND" | grep -qE "^git commit"; then
    if [ -z "$(git config user.name 2>/dev/null)" ]; then
        echo '{"decision": "block", "reason": "git user.name is not set. Run: git config --global user.name \"Your Name\""}'
        exit 0
    fi
    if [ -z "$(git config user.email 2>/dev/null)" ]; then
        echo '{"decision": "block", "reason": "git user.email is not set. Run: git config --global user.email \"you@example.com\""}'
        exit 0
    fi
fi

if echo "$COMMAND" | grep -qE "^git push"; then
    if ! git remote | grep -q .; then
        echo '{"decision": "block", "reason": "No git remote configured. Add a remote with: git remote add origin <url>"}'
        exit 0
    fi

    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")

    if echo "$REMOTE_URL" | grep -qE "(dev\.azure\.com|visualstudio\.com)"; then
        if [ -z "${AZURE-DEVOPS-TOKEN:-}" ]; then
            echo '{"decision": "block", "reason": "AZURE-DEVOPS-TOKEN is not set. Pass it at runtime: AZURE-DEVOPS-TOKEN=<pat> claude ... (see docs/platform-setup.md)"}'
            exit 0
        fi
        export GIT_CONFIG_COUNT=2
        export GIT_CONFIG_KEY_0="url.https://x-access-token:${AZURE-DEVOPS-TOKEN}@dev.azure.com/.insteadOf"
        export GIT_CONFIG_VALUE_0="https://dev.azure.com/"
        export GIT_CONFIG_KEY_1="url.https://x-access-token:${AZURE-DEVOPS-TOKEN}@visualstudio.com/.insteadOf"
        export GIT_CONFIG_VALUE_1="https://visualstudio.com/"
    else
        if [ -z "${GITHUB-TOKEN:-}" ]; then
            echo '{"decision": "block", "reason": "GITHUB-TOKEN is not set. Pass it at runtime: GITHUB-TOKEN=<token> claude ... (see docs/platform-setup.md)"}'
            exit 0
        fi
        export GIT_CONFIG_COUNT=1
        export GIT_CONFIG_KEY_0="url.https://x-access-token:${GITHUB-TOKEN}@github.com/.insteadOf"
        export GIT_CONFIG_VALUE_0="https://github.com/"
    fi
fi

exit 0
