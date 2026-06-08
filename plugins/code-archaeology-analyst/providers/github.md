# Provider: GitHub

Use this provider when `git remote get-url origin` contains `github.com`.

## Prerequisites

The `gh` CLI must be installed and authenticated:

```bash
gh auth status
```

If not authenticated, run `gh auth login` or set the `GITHUB_TOKEN` environment variable.

---

## Fetching the Issue

```bash
gh issue view ${ISSUE_NUMBER} --json number,title,body,state,labels,assignees,milestone,comments
```

Extract from the body:
- `Repository:` → `TARGET_PATH` (default: `.`)
- `Focus areas:` → `FOCUS_AREAS` (default: `""`)
- `Skip areas:` → `SKIP_AREAS` (default: `""`)
- `Max segments:` → `MAX_SEGMENTS` (default: `"auto"`)

Check that the `code-archaeology` label is present — warn if missing but continue.

---

## Posting the "Analysis in Progress" Comment

Post immediately after fetching the issue — before any codebase survey:

```bash
gh issue comment ${ISSUE_NUMBER} --body "$(cat <<'EOF'
🔍 **Codebase archaeology analysis in progress**

Segmenting the codebase and running five analysis phases: architecture mapping, pattern extraction, due diligence audit, and debt classification. The full report will be posted as a series of comments when all phases are complete. This may take several minutes.
EOF
)"
```

If posting fails, output a single warning line and continue.

---

## Posting Analysis Comments

The original issue body is **never modified**. All output is posted as **separate comments** when the full analysis is complete.

### Comment Order

| # | Heading | Skip when |
|---|---------|-----------|
| 1 | `🗺️ Architecture & Segment Map` | Never |
| 2 | `🔍 Coding Conventions` | Never |
| 3 | `🔎 Due Diligence Findings` | No findings at any severity |
| 4 | `📋 Work Backlog` | Never |
| 5 | `✅ Analysis Complete` | Never |

### Posting each comment

```bash
gh issue comment ${ISSUE_NUMBER} --body "$(cat <<'EOF'
## 🗺️ Architecture & Segment Map

${COMMENT_CONTENT}
EOF
)"
```

---

## Applying the Completion Signal

After all comments are posted:

```bash
# Create the label if it does not exist
gh label create "archaeology-complete" \
  --color "0075ca" \
  --description "Code archaeology analysis completed" 2>/dev/null || true

# Apply to the issue
gh issue edit ${ISSUE_NUMBER} --add-label "archaeology-complete"

# Remove the trigger label (optional)
gh issue edit ${ISSUE_NUMBER} --remove-label "code-archaeology" 2>/dev/null || true
```

---

## Resolving the Issue Number

If no issue number was passed:

```bash
gh issue list --label "code-archaeology" --state open \
  --json number,title,createdAt --limit 10
```

Pick the most recently created open issue with the `code-archaeology` label.

---

## Output

On completion:

```
Code archaeology analysis complete for issue #<number>: <N> segments — <N> findings (C:<n> H:<n> M:<n> L:<n>) — <N> work items — <N> comments posted
```
