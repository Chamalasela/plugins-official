# Azure DevOps Provider

Reference for all Azure DevOps REST API calls used by the incident-response plugin. All endpoints require a PAT token passed as Basic auth with an empty username.

## Authentication

```bash
B64_TOKEN=$(echo -n ":${AZURE_DEVOPS_TOKEN}" | base64)
AUTH_HEADER="Authorization: Basic ${B64_TOKEN}"
```

For legacy `visualstudio.com` hosts:
```bash
API_BASE="https://{org}.visualstudio.com/{project}"
```
For `dev.azure.com` hosts (current):
```bash
API_BASE="https://dev.azure.com/{org}/{project}"
```

---

## Work Item Operations

### Fetch incident work item

```bash
curl -s -H "${AUTH_HEADER}" \
  "${API_BASE}/_apis/wit/workitems/{id}?api-version=7.0&\$expand=all"
```

Response fields used:
- `fields["System.Title"]` — incident title
- `fields["System.Description"]` — incident body
- `fields["System.CreatedDate"]` — creation timestamp (fallback for start time)
- `fields["Microsoft.VSTS.Common.Severity"]` — severity
- `fields["System.Tags"]` — existing tags

### Post a comment on the work item

```bash
curl -s -X POST \
  -H "${AUTH_HEADER}" \
  -H "Content-Type: application/json" \
  "${API_BASE}/_apis/wit/workitems/{id}/comments?api-version=7.0-preview.3" \
  -d "{\"text\": \"${COMMENT_BODY}\"}"
```

Note: `text` supports Markdown. Use `\n` for newlines within the JSON string.

### Apply status tag to work item

```bash
curl -s -X PATCH \
  -H "${AUTH_HEADER}" \
  -H "Content-Type: application/json-patch+json" \
  "${API_BASE}/_apis/wit/workitems/{id}?api-version=7.0" \
  -d "[{\"op\": \"add\", \"path\": \"/fields/System.Tags\", \"value\": \"investigating\"}]"
```

To preserve existing tags, first fetch current tags and append:
```bash
EXISTING_TAGS=$(curl -s -H "${AUTH_HEADER}" "${API_BASE}/_apis/wit/workitems/{id}?api-version=7.0" | jq -r '.fields["System.Tags"] // ""')
NEW_TAGS="${EXISTING_TAGS}; investigating"
```

---

## Work Item Creation

### Create a Task linked to the incident

```bash
# $Task or $Bug in the URL — URL-encode the $ as %24 if your shell expands it
curl -s -X POST \
  -H "${AUTH_HEADER}" \
  -H "Content-Type: application/json-patch+json" \
  "${API_BASE}/_apis/wit/workitems/\$Task?api-version=7.0" \
  -d '[
    {"op": "add", "path": "/fields/System.Title",       "value": "[Rollback] #4821: Roll back deployment 8821 (payment-service v2.4.1)"},
    {"op": "add", "path": "/fields/System.Description", "value": "<p>Deployment 8821 finished at 13:45 UTC and is tagged <strong>likely-cause</strong>. Roll back to the previous release to restore service.</p>"},
    {"op": "add", "path": "/fields/System.Tags",        "value": "incident-response; ai-generated; 4821"},
    {"op": "add", "path": "/relations/-",               "value": {
      "rel": "System.LinkTypes.Hierarchy-Reverse",
      "url": "https://dev.azure.com/{org}/_apis/wit/workitems/{INCIDENT_ID}",
      "attributes": {"comment": "Created by incident-response agent"}
    }}
  ]'
```

The response body contains the new work item's `id` field — capture this to include in the summary output.

### Create a Bug for root-cause investigation

Replace `\$Task` with `\$Bug` in the URL. Bugs support the same field patch format.

```bash
curl -s -X POST \
  -H "${AUTH_HEADER}" \
  -H "Content-Type: application/json-patch+json" \
  "${API_BASE}/_apis/wit/workitems/\$Bug?api-version=7.0" \
  -d '[
    {"op": "add", "path": "/fields/System.Title",             "value": "[Root Cause Investigation] #4821: System.Data.SqlException cascade"},
    {"op": "add", "path": "/fields/Microsoft.VSTS.TCM.ReproSteps", "value": "<p>SqlException count rose from baseline ~0 to 87 per 5-min bucket at 14:35 UTC. Likely caused by connection pool exhaustion introduced in build 8821. Investigate maxPoolSize setting change in payment-service v2.4.1.</p>"},
    {"op": "add", "path": "/fields/System.Tags",              "value": "incident-response; ai-generated; 4821"},
    {"op": "add", "path": "/relations/-",                     "value": {
      "rel": "System.LinkTypes.Hierarchy-Reverse",
      "url": "https://dev.azure.com/{org}/_apis/wit/workitems/{INCIDENT_ID}",
      "attributes": {"comment": "Created by incident-response agent"}
    }}
  ]'
```

### Work item type reference

| Category | Work item type URL segment |
|---|---|
| Task (mitigation, rollback, follow-up) | `\$Task` |
| Bug (root cause, exception investigation) | `\$Bug` |

### Link type reference

| Relation | Meaning |
|---|---|
| `System.LinkTypes.Hierarchy-Reverse` | Child → Parent (task is a child of the incident) |
| `System.LinkTypes.Related` | Peer relationship (use if the org doesn't allow child links on the incident type) |

---

## Deployment History

### Pipeline build runs in time window

```bash
curl -s -H "${AUTH_HEADER}" \
  "${API_BASE}/_apis/build/builds?minTime={window_start}&maxTime={window_end}&statusFilter=completed&api-version=7.0" \
  | jq '.value[] | {id, buildNumber, finishTime, result, sourceBranch, repositoryName: .repository.name, requestedFor: .requestedFor.displayName}'
```

### Release deployments in time window

```bash
curl -s -H "${AUTH_HEADER}" \
  "${API_BASE}/_apis/release/deployments?minStartedTime={window_start}&maxStartedTime={window_end}&deploymentStatus=succeeded&api-version=7.0" \
  | jq '.value[] | {id, releaseId, releaseName, releaseDefinitionName, completedOn, environmentName: .releaseEnvironment.name}'
```

### Fetch specific pipeline run details

```bash
curl -s -H "${AUTH_HEADER}" \
  "${API_BASE}/_apis/build/builds/{buildId}?api-version=7.0" \
  | jq '{id, buildNumber, finishTime, sourceBranch, sourceVersion, repository, triggerInfo}'
```

---

## Error Codes

| HTTP | Meaning | Action |
|---|---|---|
| 401 | Invalid token | Check `AZURE_DEVOPS_TOKEN` value and expiry |
| 403 | Insufficient scope | Ensure PAT has Work Items (R/W), Build (R), Release (R) |
| 404 | Work item not found | Verify the incident ID and project name |
| 429 | Rate limited | Back off 5 seconds and retry once |
