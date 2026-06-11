---
name: gather-test-context
description: Phase 1 of chatbot-tester. For PR/issue/wi entry types, fetches the artefact content and scans for a testable URL. For direct URL runs, TEST_URL is already set. Validates the knowledge file widget block. Checks if login is required. Outputs TEST_URL and REQUIRES_LOGIN.
disable-model-invocation: true
---

# Phase 1 — Gather Test Context

This skill is invoked by the **orchestrator** agent. It is not a standalone slash command.

## Inputs

| Variable | Source | Description |
|---|---|---|
| `ENTRY_TYPE` | orchestrator | `pr`, `issue`, `wi`, or `url` |
| `ENTRY_ID` | orchestrator | PR number, issue number, or work item ID (not set for `url`) |
| `PLATFORM` | orchestrator | `GitHub`, `AzureDevOps`, or `DirectURL` |
| `TEST_URL` | orchestrator | Already set if `ENTRY_TYPE=url`; otherwise empty |
| `KNOWLEDGE` | orchestrator | Parsed contents of `knowledge/chatbot-tester.json` |

## Outputs

| Variable | Description |
|---|---|
| `TEST_URL` | The URL the browser session will open |
| `REQUIRES_LOGIN` | `true` if credentials are declared in the knowledge file; otherwise `false` |

---

## Step 1: Resolve URL

**If `ENTRY_TYPE=url`:** `TEST_URL` is already set. Skip to Step 2.

**If `ENTRY_TYPE=pr` (GitHub):**

```bash
REPO=$(git remote get-url origin | sed 's|.*github.com[:/]\(.*\)\.git|\1|;s|.*github.com[:/]\(.*\)|\1|')
gh pr view ${ENTRY_ID} --repo ${REPO} --json number,title,body,comments,url
```

**If `ENTRY_TYPE=issue` (GitHub):**

```bash
REPO=$(git remote get-url origin | sed 's|.*github.com[:/]\(.*\)\.git|\1|;s|.*github.com[:/]\(.*\)|\1|')
gh issue view ${ENTRY_ID} --repo ${REPO} --json number,title,body,comments
```

**If `ENTRY_TYPE=pr` (Azure DevOps):**

Parse `API_BASE` and `AZURE_REPO` per `providers/azure-devops.md`.

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${ENTRY_ID}?api-version=7.1"
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${ENTRY_ID}/threads?api-version=7.1"
```

**If `ENTRY_TYPE=wi` (Azure DevOps):**

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${ENTRY_ID}?api-version=7.1&\$expand=all"
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${ENTRY_ID}/comments?api-version=7.1-preview.4"
```

**Scan for URL** from collected content. Look for any `https?://[^\s\)\"\']+` URL preceded by labels such as: `Preview URL:`, `Staging URL:`, `Test at:`, `Deploy preview:`, `Demo:`, `Environment:`, `App URL:`.

If no URL is found, post a BLOCKED comment via the correct provider and STOP:

```
chatbot-tester BLOCKED: No testable URL found.

Add a URL to the PR/issue description or a comment using one of these labels:
  Preview URL: https://...
  Staging URL: https://...
  App URL: https://...
```

Store the found URL as `TEST_URL`.

---

## Step 2: Check Login Requirement

If `KNOWLEDGE` contains a `credentials` block with `username_env` and `password_env` fields → set `REQUIRES_LOGIN=true`.

Otherwise → set `REQUIRES_LOGIN=false`.

If `REQUIRES_LOGIN=true`, verify the referenced env vars are set:

```bash
if [ -z "${TEST_USER:-}" ] || [ -z "${TEST_PASS:-}" ]; then
  echo "chatbot-tester WARNING: credentials declared in knowledge file but TEST_USER or TEST_PASS env vars are not set. Login step will be BLOCKED."
fi
```

(The actual env var names come from `KNOWLEDGE.credentials.username_env` and `KNOWLEDGE.credentials.password_env` — substitute accordingly.)

---

## Completion

Hand off to `skills/run-playwright-session/SKILL.md` with `TEST_URL`, `REQUIRES_LOGIN`, `KNOWLEDGE`, `PLATFORM`, `ENTRY_TYPE`, `ENTRY_ID` in scope.
