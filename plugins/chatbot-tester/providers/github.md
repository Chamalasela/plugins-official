# Provider: GitHub

Use this provider when `PLATFORM=GitHub` (URL matched `github.com/*/issues/*`).

## Prerequisites

The `gh` CLI must be installed and authenticated. Verify with:

```bash
gh auth status
```

If not authenticated, run `gh auth login` or set the `GITHUB_TOKEN` environment variable.

### Token Permissions

| Permission | Access | Why it's needed |
|---|---|---|
| **Metadata** | Read | Resolve repository owner and name |
| **Issues** | Read & Write | Fetch issue body and comments; post result comment |

---

## Parsing the Issue URL

Parse `GITHUB_OWNER`, `GITHUB_REPO`, and `ISSUE_NUMBER` from the input URL.

URL format: `https://github.com/{owner}/{repo}/issues/{number}`

```bash
ISSUE_URL="https://github.com/owner/repo/issues/42"
GITHUB_OWNER=$(echo "$ISSUE_URL" | sed 's|https://github.com/||' | cut -d'/' -f1)
GITHUB_REPO=$(echo "$ISSUE_URL"  | sed 's|https://github.com/||' | cut -d'/' -f2)
ISSUE_NUMBER=$(echo "$ISSUE_URL" | sed 's|https://github.com/||' | cut -d'/' -f4)
```

---

## Fetching Issue Content

```bash
gh issue view ${ISSUE_NUMBER} --repo ${GITHUB_OWNER}/${GITHUB_REPO} --json number,title,body,state,labels,comments
```

---

## Posting the "Test in Progress" Comment

The orchestrator writes the body to `/tmp/cbt_starting.md` before calling this step.

```bash
gh issue comment ${ISSUE_NUMBER} --repo ${GITHUB_OWNER}/${GITHUB_REPO} --body-file /tmp/cbt_starting.md
```

---

## Posting a BLOCKED Comment

```bash
gh issue comment ${ISSUE_NUMBER} --repo ${GITHUB_OWNER}/${GITHUB_REPO} --body "${BLOCKED_MESSAGE}"
```

---

## Posting the Test Report

Construct the full report body following `styles/report-template.md`, then post it.

```bash
gh issue comment ${ISSUE_NUMBER} --repo ${GITHUB_OWNER}/${GITHUB_REPO} --body "$(cat <<'EOF'
${REPORT_BODY}
EOF
)"
```
