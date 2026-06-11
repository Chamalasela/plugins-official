---
name: gather-test-context
description: Phase 1 of web-app-tester. Fetches the PR, issue, or work item content (description, comments, linked items) via the appropriate provider, scans it for a testable URL, applies the production-URL safety check, and either finds an existing structured test plan or auto-generates one. For wi entry on Azure DevOps, uses bug repro steps as the test plan seed. Outputs TEST_URL, PRODUCTION_WARNING, TEST_PLAN, and (for wi) LINKED_PR_ID for the execution phase.
disable-model-invocation: true
---

# Phase 1 — Gather Test Context

This skill is invoked by the **orchestrator** agent. It is not a standalone slash command.

## Inputs

| Variable | Source | Description |
|---|---|---|
| `ENTRY_TYPE` | orchestrator | `pr`, `issue`, or `wi` |
| `ENTRY_ID` | orchestrator | The PR number, issue number, or work item ID |
| `PLATFORM` | orchestrator | `GitHub` or `AzureDevOps` |
| `BYPASS_PRODUCTION_CHECK` | orchestrator | `true` to skip the production URL safety check; otherwise `false` |
| `BYPASSED_BY` | orchestrator | Identity of the requester who set `--bypass-production-check`; empty string if bypass is not active |

## Outputs

| Variable | Description |
|---|---|
| `TEST_URL` | The URL the test plan will run against |
| `PRODUCTION_WARNING` | `true` if the URL appears to be production and bypass is not active; otherwise `false` |
| `BYPASS_PRODUCTION_CHECK` | Passed through unchanged |
| `BYPASSED_BY` | Passed through unchanged |
| `TEST_PLAN` | Either an existing plan from the content or one auto-generated from context |
| `LINKED_PR_ID` | Azure DevOps only, `wi` entry: the PR linked to the work item (used for posting the report) |

If a required output cannot be produced (e.g. no testable URL), this skill posts a comment and stops. Do not proceed to Phase 2.

For full provider command reference, see:
- `providers/github.md` (GitHub)
- `providers/azure-devops.md` (Azure DevOps)

---

## Step 1: Fetch Content

### GitHub — `ENTRY_TYPE == pr`

Resolve the `--repo` flag from the git remote before running gh commands:
```bash
REPO=$(git remote get-url origin | sed 's|.*github.com[:/]\(.*\)\.git|\1|;s|.*github.com[:/]\(.*\)|\1|')
```

```bash
gh pr view ${ENTRY_ID} --repo ${REPO} --json number,title,body,state,headRefName,baseRefName,url,author,labels,commits,closingIssuesReferences,comments
gh pr view ${ENTRY_ID} --repo ${REPO} --json closingIssuesReferences --jq '.closingIssuesReferences[].number'
```

For each linked issue number discovered:
```bash
gh issue view ${ISSUE_NUMBER} --repo ${REPO} --json number,title,body,state,labels,comments
```

Collect: PR title, description, all comments, commit messages, linked issue descriptions and comments.

---

### GitHub — `ENTRY_TYPE == issue`

Resolve the `--repo` flag from the git remote before running gh commands:
```bash
REPO=$(git remote get-url origin | sed 's|.*github.com[:/]\(.*\)\.git|\1|;s|.*github.com[:/]\(.*\)|\1|')
```

```bash
gh issue view ${ENTRY_ID} --repo ${REPO} --json number,title,body,state,labels,assignees,comments,projectItems
```

Discover linked PRs:
```bash
gh api "repos/${REPO}/issues/${ENTRY_ID}/timeline" --paginate \
  --jq '.[] | select(.event=="cross-referenced" or .event=="closed") | .source.issue.number // empty'
gh pr list --repo ${REPO} --search "${ENTRY_ID} in:body" --state all --json number,title,state,headRefName,url,body --limit 20
```

Collect: issue title, description, all comments, linked PR descriptions.

---

### Azure DevOps — `ENTRY_TYPE == pr`

Parse the remote URL and set `API_BASE`, `AZURE_REPO` per `providers/azure-devops.md`.

```bash
# PR metadata
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${ENTRY_ID}?api-version=7.1"

# PR threads (all comments)
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${ENTRY_ID}/threads?api-version=7.1"

# Linked work items
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${ENTRY_ID}/workitems?api-version=7.1"
```

For each linked work item, fetch to extract acceptance criteria or description:
```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${WI_ID}?api-version=7.1&\$expand=all"
```

Collect: PR title, description, all thread comment contents (concatenated), linked work item descriptions and acceptance criteria.

---

### Azure DevOps — `ENTRY_TYPE == wi`

Parse the remote URL and set `API_BASE`, `AZURE_REPO` per `providers/azure-devops.md`.

```bash
# Work item with all fields and relations
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${ENTRY_ID}?api-version=7.1&\$expand=all"

# Work item comments
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${ENTRY_ID}/comments?api-version=7.1-preview.4"
```

**Auto-detect work item type** from `fields.System.WorkItemType`:
- `Bug` → extract repro steps (`Microsoft.VSTS.TCM.ReproSteps`) and root cause (`Microsoft.VSTS.Common.RootCause`). The repro steps are the **primary test plan seed** — treat them as a structured step list if they enumerate navigable steps.
- `Product Backlog Item`, `User Story`, `Feature` → extract acceptance criteria (`Microsoft.VSTS.Common.AcceptanceCriteria`).

**Discover linked PRs** from the work item relations (see `providers/azure-devops.md`). Store the first active (non-abandoned) linked PR ID as `LINKED_PR_ID`. If a linked PR is found, fetch its metadata and threads:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${LINKED_PR_ID}?api-version=7.1"
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "${API_BASE}/_apis/git/repositories/${AZURE_REPO}/pullrequests/${LINKED_PR_ID}/threads?api-version=7.1"
```

Collect: work item title, description, repro steps or acceptance criteria, all work item comments, and (if a linked PR exists) linked PR description and all linked PR thread comments.

If no linked PR is found, set `LINKED_PR_ID=""` and continue — the testable URL will be scanned from the work item content directly, and the report will be posted on the work item itself.

---

## Step 2: Find the Test URL

Scan all collected content (description, every comment, repro steps, commit messages) for a URL matching `https?://[^\s\)\"\']+`.

Prioritise URLs preceded by any of these labels (case-insensitive):
- `Preview URL:`
- `Staging URL:`
- `Test at:`
- `Deploy preview:`
- `Demo:`
- `Environment:`

Exclude URLs that appear inside fenced code blocks (``` or `~~~`).

**If no URL is found**, post the appropriate "no testable URL" comment via the correct provider and STOP — do not proceed to Phase 2:

- GitHub PR → `providers/github.md` "No URL Found — PR" command
- GitHub Issue → `providers/github.md` "No URL Found — Issue" command
- Azure DevOps PR → `providers/azure-devops.md` "No URL Found — PR" command
- Azure DevOps Work Item → `providers/azure-devops.md` "No URL Found — Work Item" command

Store the found URL as `TEST_URL`.

---

## Step 3: Production URL Safety Check

If `BYPASS_PRODUCTION_CHECK` is `true`, set `PRODUCTION_WARNING=false` and skip to Step 4 — the production check is bypassed at the user's explicit request.

Otherwise, if `TEST_URL` does not contain any of the following substrings: `staging`, `preview`, `dev`, `test`, `pr-`, `localhost`, `127.0.0.1`, `.local`, a PR number, or an issue/work item number — set `PRODUCTION_WARNING=true`.

If `PRODUCTION_WARNING=true`, restrict execution to **read-only steps only**. Never submit forms, click destructive actions (delete, remove, reset), or trigger data-modifying operations.

The execution phase enforces this at the per-step level — see `skills/run-playwright-session/SKILL.md`.

---

## Step 4: Find a Test Plan

### Azure DevOps `wi` entry — Bug repro steps

If the work item type is `Bug` and the repro steps field contains a numbered or bulleted list with at least two action verbs (Navigate, Go to, Click, Fill, Verify, Assert, Check, Submit, Open, etc.) → use repro steps directly as `TEST_PLAN` and skip to Phase 2. Do not post a comment.

If repro steps exist but are not in a structured step format, use them as context for Step 4b auto-generation.

### All other entry types — Scan for existing test plan

Scan the full body and all comments for a structured step list meeting ALL of these criteria:
- Numbered or bulleted list
- Contains at least two action verbs from: Navigate, Go to, Click, Tap, Fill, Enter, Type, Verify, Assert, Check, Confirm, Ensure, Submit, Expect, Open, Close, Scroll, Select, Upload
- Appears under a heading or label such as: `Test Plan`, `QA Steps`, `Testing Steps`, `Acceptance Criteria`, `Verification Steps`, or is an explicit numbered list of at least 3 steps

Also accept a test plan generated by the `test-strategist` plugin (look for headings like `## Test Strategy`, `## Test Cases`, `## Automated Test Steps`).

**If a test plan is found** → store it as `TEST_PLAN` and finish — proceed directly to Phase 2 using it as-is.

**If no test plan is found** → run Step 4b.

---

## Step 4b: Auto-Generate Test Plan

Based on the title, description, commits, repro steps (Bug), acceptance criteria (PBI/Feature), and linked item content, derive a focused test plan covering:

1. **Primary user-facing change** — the core behaviour described or implied
2. **Implied UI interactions** — forms, navigation flows, state changes, error states
3. **Happy-path scenario** — the expected successful user journey
4. **Edge / negative scenario** — at least one boundary or error case

For **Bug work items**: the repro steps define the unhappy path — include them verbatim as step(s) and add verification steps that confirm the fix resolves them.

Format the plan as a numbered list with action verbs. Keep steps concrete and navigable (reference page paths, button labels, form fields as described in the content).

Post this plan comment via the correct provider before executing:

- GitHub PR → `providers/github.md` "Auto-Generated Plan — PR" command
- GitHub Issue → `providers/github.md` "Auto-Generated Plan — Issue" command
- Azure DevOps PR → `providers/azure-devops.md` "Auto-Generated Plan — PR" command
- Azure DevOps Work Item → `providers/azure-devops.md` "Auto-Generated Plan — Work Item" command (posts on `LINKED_PR_ID`)

Store the auto-generated plan as `TEST_PLAN`.

---

## Completion

When this skill finishes successfully, hand off to `skills/run-playwright-session/SKILL.md` with `TEST_URL`, `PRODUCTION_WARNING`, `BYPASS_PRODUCTION_CHECK`, `BYPASSED_BY`, `TEST_PLAN`, `PLATFORM`, `ENTRY_TYPE`, `ENTRY_ID`, and (if applicable) `LINKED_PR_ID` in scope.
