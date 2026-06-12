# Provider: Azure DevOps

Use this provider when `PLATFORM=AzureDevOps` (URL matched `dev.azure.com/*/_workitems/*`).

## Prerequisites

Required environment variable:

| Variable | Purpose |
|---|---|
| `AZURE_DEVOPS_TOKEN` | Azure DevOps Personal Access Token (PAT) |

### Token Permissions

| Permission | Access | Why it's needed |
|---|---|---|
| **Work Items** | Read & Write | Fetch work item content; post result comment |

---

## Parsing the Work Item URL

Parse `AZURE_ORG`, `AZURE_PROJECT`, and `WORK_ITEM_ID` from the input URL.

URL format: `https://dev.azure.com/{org}/{project}/_workitems/edit/{id}`

```bash
WI_URL="https://dev.azure.com/myorg/myproject/_workitems/edit/1234"
AZURE_ORG=$(echo "$WI_URL"      | sed 's|https://dev.azure.com/||' | cut -d'/' -f1)
AZURE_PROJECT=$(echo "$WI_URL"  | sed 's|https://dev.azure.com/||' | cut -d'/' -f2)
WORK_ITEM_ID=$(echo "$WI_URL"   | sed 's|.*/_workitems/edit/||' | cut -d'/' -f1 | cut -d'?' -f1)
API_BASE="https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}"
```

---

## Fetching Work Item Content

```bash
curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.1&\$expand=all"

curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?api-version=7.1-preview.4"
```

---

## Posting the Starting Comment

The orchestrator writes the body to `/tmp/cbt_starting.md` before calling this step.

```bash
curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d "$(python3 -c "
import json, pathlib
body = pathlib.Path('/tmp/cbt_starting.md').read_text(encoding='utf-8')
print(json.dumps({'text': body}))
")"
```

---

## Posting a BLOCKED Comment

```bash
curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d "$(python3 -c "
import json, sys
body = sys.stdin.read()
print(json.dumps({'text': body}))
" <<'BLOCKED'
${BLOCKED_MESSAGE}
BLOCKED
)"
```

---

## Posting the Test Report

```bash
curl -s -u ":${AZURE_DEVOPS_TOKEN}" \
  -X POST \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/${WORK_ITEM_ID}/comments?format=markdown&api-version=7.1-preview.4" \
  -d "$(python3 -c "
import json, sys
body = sys.stdin.read()
print(json.dumps({'text': body}))
" <<'REPORT'
${REPORT_BODY}
REPORT
)"
```
