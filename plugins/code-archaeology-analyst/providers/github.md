# Provider: GitHub

Use this provider when `git remote get-url origin` contains `github.com`.

## Prerequisites

The `gh` CLI must be installed and authenticated. Verify with:

```bash
gh auth status
```

If not authenticated, run `gh auth login` or set the `GITHUB_TOKEN` environment variable.

---

## Fetching the Issue

Fetch the triggering issue with all metadata:

```bash
gh issue view ${ISSUE_NUMBER} --json number,title,body,state,labels,assignees,milestone,comments
```

Extract from the JSON response:
- `title` — issue title (context for the analysis)
- `body` — issue description — parse for `**Target path:**` and `**Modules of interest:**`
- `labels[].name` — check for `code-archaeology` tag
- `assignees[].login` — who requested the analysis
- `comments[].body` — any prior context

**Parsing the issue body:**

Look for optional structured fields:
```
**Target path:** src/payments        → TARGET_PATH
**Modules of interest:** src/auth    → MODULES_OF_INTEREST
```

If not present, default `TARGET_PATH` to `.` (repo root).

---

## Posting the "Analysis in Progress" Comment

Post immediately after fetching the issue — before any codebase survey or sub-agent work:

```bash
gh issue comment ${ISSUE_NUMBER} --body "$(cat <<'EOF'
🔍 **Code archaeology analysis in progress**

Scanning the codebase module by module — mapping capabilities, extracting patterns, and classifying work into Enhancement / Remediation / Migration Bolts. The analysis will be posted as a series of comments when complete. This may take a few minutes.
EOF
)"
```

If posting fails, output a single warning line and continue.

---

## Posting Analysis Comments

The original issue body is **never modified**. All analysis output is posted as **separate comments** — one per section.

### Comment Order

| # | Heading | Source | Skip when |
|---|---------|--------|-----------|
| 1 | `🗺️ Module Map & Capability Map` | module-scanner | Never |
| 2 | `🔍 Code Patterns & Conventions` | pattern-extractor | Never |
| 3 | `📋 Work Classification` | work-classifier | Never |
| 4 | `🛡️ Blast Radius Controls` | coverage-analyst | `--no-coverage` |
| 5 | `✅ Analysis Complete` | Orchestrator | Never |

Skip any comment whose source produced no meaningful findings.

### Posting each comment

```bash
gh issue comment ${ISSUE_NUMBER} --body "$(cat <<'EOF'
## 🗺️ Module Map & Capability Map

${COMMENT_CONTENT}
EOF
)"
```

---

## Applying the Completion Signal

After posting all comments, apply the completion label:

```bash
gh issue edit ${ISSUE_NUMBER} --add-label "archaeology-complete"
```

Also remove the trigger label (optional — preserves the history if kept):

```bash
gh issue edit ${ISSUE_NUMBER} --remove-label "code-archaeology"
```

If the `archaeology-complete` label doesn't exist in the repo, create it first:

```bash
gh label create "archaeology-complete" --color "0075ca" --description "Code archaeology analysis has been completed" 2>/dev/null || true
```

---

## Resolving the Issue Number

If no issue number was passed as an argument:

```bash
gh issue list --label "code-archaeology" --state open --json number,title,createdAt --limit 10
```

Pick the most recently created open issue with the `code-archaeology` label.

---

## Output

On completion:

```
Code archaeology analysis complete for issue #<number>: <N> modules — <N> Enhancement | <N> Remediation | <N> Migration — <N> comments posted
```
