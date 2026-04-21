# GitHub Provider

Reference for all GitHub CLI and API calls used by the incident-response plugin. Uses the `gh` CLI exclusively — no direct REST calls for issue operations.

## Authentication

```bash
# Verify auth status
gh auth status

# Or set via env var (CI/CD)
export GITHUB_TOKEN="{token}"
```

Parse owner and repo from remote URL:
```bash
REMOTE_URL=$(git remote get-url origin)
# https://github.com/{owner}/{repo}.git  →  strip prefix and .git suffix
OWNER=$(echo "$REMOTE_URL" | sed 's|https://github.com/||' | cut -d'/' -f1)
REPO=$(echo "$REMOTE_URL" | sed 's|https://github.com/||' | cut -d'/' -f2 | sed 's|\.git$||')
```

---

## Issue Operations

### Fetch incident issue

```bash
gh issue view {number} \
  --json number,title,body,labels,createdAt,comments,assignees,milestone,state
```

Fields used:
- `title` — incident title
- `body` — incident description
- `createdAt` — creation timestamp (fallback for start time)
- `labels[].name` — look for severity labels (`SEV-1`, `P0`, `critical`, etc.)

### Post a comment on the issue

```bash
gh issue comment {number} --body "${COMMENT_BODY}"
```

For multiline bodies use a heredoc or write to a temp file:
```bash
gh issue comment {number} --body-file /tmp/comment_body.md
```

### Apply status label

```bash
gh issue edit {number} --add-label "investigating"
```

Labels must exist in the repository. If the label does not exist, create it first:
```bash
gh label create "investigating" --color "FFA500" --description "Incident under AI-assisted investigation"
gh label create "resolved" --color "0E8A16" --description "Incident root cause identified and mitigated"
gh label create "needs-data" --color "D93F0B" --description "Insufficient signal — more data needed"
```

---

## GitHub Actions (Deployment History)

### Workflow runs in blast radius window

```bash
gh api "repos/${OWNER}/${REPO}/actions/runs" \
  --field "created=>=${WINDOW_START}" \
  --field "created=<=${WINDOW_END}" \
  --jq '.workflow_runs[] | {id, name, head_sha, created_at, updated_at, conclusion, head_branch, display_title, path}'
```

### Fetch details of a specific run

```bash
gh api "repos/${OWNER}/${REPO}/actions/runs/{run_id}" \
  --jq '{id, name, head_sha, head_branch, created_at, updated_at, conclusion, html_url}'
```

### List jobs for a run (to identify which service was deployed)

```bash
gh api "repos/${OWNER}/${REPO}/actions/runs/{run_id}/jobs" \
  --jq '.jobs[] | {id, name, conclusion, started_at, completed_at}'
```

---

## Error Codes

| Exit Code / Status | Meaning | Action |
|---|---|---|
| `gh: Not Found (HTTP 404)` | Issue not found | Verify the issue number and repository |
| `gh: Must have push access` | Insufficient scope | Check token scopes include `repo` |
| `gh: authentication required` | Not logged in | Run `gh auth login` or set `GITHUB_TOKEN` |
