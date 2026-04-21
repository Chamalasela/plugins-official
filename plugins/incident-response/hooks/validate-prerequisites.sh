#!/usr/bin/env bash
set -euo pipefail

# Detect platform from git remote
REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)

if [[ -z "$REMOTE_URL" ]]; then
  echo "ERROR: No git remote 'origin' found. Run from a git repository with a remote configured." >&2
  exit 1
fi

# Azure DevOps checks
if echo "$REMOTE_URL" | grep -qE "(dev\.azure\.com|visualstudio\.com)"; then
  if [[ -z "${AZURE_DEVOPS_TOKEN:-}" ]]; then
    echo "ERROR: AZURE_DEVOPS_TOKEN is not set. Create a PAT with Work Items (Read & Write), Build (Read), and Release (Read) scopes. See docs/platform-config.md." >&2
    exit 1
  fi
fi

# GitHub checks
if echo "$REMOTE_URL" | grep -q "github\.com"; then
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    if ! gh auth status >/dev/null 2>&1; then
      echo "ERROR: GitHub authentication not configured. Run 'gh auth login' or set GITHUB_TOKEN. See docs/platform-config.md." >&2
      exit 1
    fi
  fi
fi

# Azure Monitor checks (only if workspace ID is set — it is optional)
if [[ -n "${LOG_ANALYTICS_WORKSPACE_ID:-}" ]]; then
  if ! command -v az >/dev/null 2>&1; then
    echo "ERROR: LOG_ANALYTICS_WORKSPACE_ID is set but 'az' CLI is not on PATH. Install the Azure CLI: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli" >&2
    exit 1
  fi
fi

exit 0
