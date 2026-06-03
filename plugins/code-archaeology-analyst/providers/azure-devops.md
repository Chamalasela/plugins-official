# Provider: Azure DevOps

Use this provider when `git remote get-url origin` contains `dev.azure.com` or `visualstudio.com`.

## Prerequisites

The Azure DevOps REST API is called directly via `curl` using a Personal Access Token (PAT).

Required environment variable:

| Variable | Purpose |
|---|---|
| `AZURE-DEVOPS-TOKEN` | Azure DevOps PAT — must have `Work Items (Read & Write)` scopes |

Optional overrides:

| Variable | Default |
|---|---|
| `AZURE_ORG` | Parsed from remote URL |
| `AZURE_PROJECT` | Parsed from remote URL |

---

## Parsing the Remote URL

```bash
REMOTE=$(git remote get-url origin)

# HTTPS format: https://dev.azure.com/{org}/{project}/_git/{repo}
AZURE_ORG=$(echo "$REMOTE"     | sed 's|https://dev.azure.com/||' | cut -d'/' -f1)
AZURE_PROJECT=$(echo "$REMOTE" | sed 's|https://dev.azure.com/||' | cut -d'/' -f2)

# Legacy format: https://{org}.visualstudio.com/{project}/_git/{repo}
# AZURE_ORG=$(echo "$REMOTE"     | sed 's|https://||' | cut -d'.' -f1)
# AZURE_PROJECT=$(echo "$REMOTE" | cut -d'/' -f4)
```

---

## Fetching Work Item Details

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.1&\$expand=all"
```

Extract:
- `fields.System.Title` — work item title
- `fields.System.Description` — description (HTML) — parse for `Target path:` and `Modules of interest:`
- `fields.System.Tags` — verify `code-archaeology` tag is present
- `fields.System.AssignedTo` — who requested the analysis
- `fields.System.IterationPath` — sprint/iteration context

**Parsing the description:**

Strip HTML tags and look for:
```
Target path: src/payments        → TARGET_PATH
Modules of interest: src/auth    → MODULES_OF_INTEREST
```

If not present, default `TARGET_PATH` to `.` (repo root).

---

## Posting the Starting Comment

Post immediately after fetching the work item — before any codebase survey or sub-agent work.

Azure DevOps requires `format=markdown` to render Markdown correctly:

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d '{"text":"🔍 **Code archaeology analysis in progress**\n\nScanning the codebase module by module — mapping capabilities, extracting patterns, and classifying work into Enhancement / Remediation / Migration Bolts. The analysis will be posted as a series of comments when complete. This may take a few minutes."}'
```

If posting fails, output a single warning line and continue.

---

## Posting Analysis Comments

The original work item description is **never modified**. All analysis output is posted as **separate comments**.

### Comment Order

| # | Heading | Source | Skip when |
|---|---------|--------|-----------|
| 1 | `🗺️ Module Map & Capability Map` | module-scanner | Never |
| 2 | `🔍 Code Patterns & Conventions` | pattern-extractor | Never |
| 3 | `📋 Work Classification` | work-classifier | Never |
| 4 | `🛡️ Blast Radius Controls` | coverage-analyst | `--no-coverage` |
| 5 | `✅ Analysis Complete` | Orchestrator | Never |

### Posting each comment

```bash
curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d "$(python3 -c "
import json, sys
body = sys.stdin.read()
print(json.dumps({'text': body}))
" <<'COMMENT'
${COMMENT_BODY}
COMMENT
)"
```

---

## Applying the Completion Tag

After posting all comments, add the `archaeology-complete` tag without replacing existing tags:

```bash
EXISTING_TAGS=$(curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  "https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.1&fields=System.Tags" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('fields',{}).get('System.Tags',''))")

NEW_TAGS="${EXISTING_TAGS}; archaeology-complete"

curl -s -u ":${AZURE-DEVOPS-TOKEN}" \
  -X PATCH \
  -H "Content-Type: application/json-patch+json" \
  "https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.1" \
  -d "$(python3 -c "
import json
print(json.dumps([
  {'op': 'replace', 'path': '/fields/System.Tags', 'value': '''${NEW_TAGS}'''}
]))
")"
```

---

## Output

On completion:

```
Code archaeology analysis complete for work item #<id>: <N> modules — <N> Enhancement | <N> Remediation | <N> Migration — <N> comments posted
```
