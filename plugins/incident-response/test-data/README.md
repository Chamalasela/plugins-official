# Test Data — INC-4821: Payment Service Incident

Realistic mock data for testing the incident-response plugin without access to live Azure DevOps, GitHub, or Azure Monitor.

---

## Scenario

**What happened:** `payment-service` v2.4.1 was deployed at 13:45 UTC. The release included a DB schema migration for a new loyalty points feature. The migration introduced an unintentional change to connection pool settings, causing connection pool exhaustion under normal production load. Errors began rising ~20 minutes after deployment and reached critical levels by 14:30 UTC, when the incident was formally opened.

**Secondary impact:** `order-fulfillment-service` started failing because payment authorization calls were timing out.

**Expected plugin output:**
- Build `8821` (payment-service.2024.3.15.1) tagged as **`likely-cause`**
- Build `8819` (shared-config.2024.3.15.1) tagged as **`possible-cause`**
- Build `8815` (analytics-service.2024.3.15.1) tagged as **`unrelated`**
- `System.TimeoutException` and `System.Data.SqlException` identified as dominant exception types
- First anomaly at **2024-03-15T14:05:00Z** (20 minutes after deployment)
- Response time anomaly: 181ms baseline → 2410ms peak
- Status signal: **`investigating`**
- Rollback candidates: 8821, 8819

---

## Files

| File | Contents |
|---|---|
| `mock-incident.md` | Plain text incident description — use as Generic platform input |
| `mock-deployments.json` | 3 pipeline builds in the blast radius window (ADO build API format) |
| `mock-logs.json` | KQL query results showing error spike from AppExceptions table |
| `mock-metrics.json` | `az monitor metrics list` output with AverageResponseTime, Http5xx, CPU, Memory |
| `mock-workitem-bug.json` | ADO REST API response for `POST /_apis/wit/workitems/$Bug` — root cause investigation bug created by the agent for INC-4821, linked to the parent incident work item |

---

## How to Run Against Test Data

### Step 1 — Set environment variables

```bash
export METRICS_SOURCE=plugins/incident-response/test-data/mock-metrics.json
# INCIDENT_WINDOW_HOURS defaults to 2, which covers the 12:30-14:30 window
```

### Step 2 — Start Claude Code with the plugin

```bash
claude --plugin-dir /path/to/plugins-official/plugins/incident-response
```

### Step 3 — Run the command

```
/incident-response plugins/incident-response/test-data/mock-incident.md
```

The orchestrator will detect Generic platform (no git remote matching ADO or GitHub — or run from outside a git repo), read `mock-incident.md` as the incident, and write `incident-response-report.md` to the current directory.

### Step 4 — Inspect the output

```bash
cat incident-response-report.md
```

Verify:
- All 5 sections are present
- Build 8821 is tagged `likely-cause`
- First anomaly is at 14:05 UTC
- Rollback section lists deployment 8821
- Status signal is `investigating`

---

## Simulating Log Queries

The `mock-logs.json` file is formatted as the output of `az monitor log-analytics query --output json`. To make the log-analyzer read it:

```bash
export METRICS_SOURCE=plugins/incident-response/test-data/mock-logs.json
```

The log-analyzer checks whether the filename contains `logs` and reads it as pre-queried results, skipping the `az` CLI call.

For a full test with both logs and metrics, use two separate env vars — the metrics-analyzer reads `METRICS_SOURCE` for metrics data, and the log-analyzer reads it for log data. To test both simultaneously, copy one of the files under a different name and adjust accordingly, or run each analyst phase separately.

---

## Testing Work Item Creation (Bug)

The `mock-workitem-bug.json` file simulates the ADO API response when the incident-response agent creates a root cause investigation bug linked to INC-4821.

**What it represents:**
- A `Bug` work item (ID 9102) created at `2024-03-15T15:02:00Z` — 32 minutes after the incident was opened
- Title: `[Root Cause Investigation] #4821: DB connection pool exhaustion — payment-service v2.4.1`
- Severity `1 - Critical`, Priority `1`
- Repro steps populated from the mitigation advisor's `ROOT_CAUSE_SUMMARY` and log/metrics findings
- Tagged `INC-4821; ai-generated; incident-response; payment-service; sev2`
- Linked to parent incident work item 4821 via `System.LinkTypes.Hierarchy-Reverse`

**How the agent uses this shape:** When `ROOT_CAUSE_CONFIDENCE: high` is returned by the mitigation advisor and the platform is Azure DevOps, the post-response phase calls:

```bash
curl -s -X POST \
  -H "Authorization: Basic ${B64_TOKEN}" \
  -H "Content-Type: application/json-patch+json" \
  "https://dev.azure.com/{org}/{project}/_apis/wit/workitems/\$Bug?api-version=7.0" \
  -d @payload.json
```

The new bug ID is extracted from `response.id` and included in the incident summary comment.

**Verifying the shape:** Confirm the response contains:
- `fields["System.WorkItemType"] == "Bug"`
- `fields["System.Tags"]` includes `INC-4821`
- `relations[0].rel == "System.LinkTypes.Hierarchy-Reverse"` pointing to work item 4821
- `fields["Microsoft.VSTS.Common.Severity"] == "1 - Critical"`

---

## Extending the Test Data

To test additional scenarios:

| Scenario | Change |
|---|---|
| No deployments in window | Set `mock-deployments.json` `count` to 0 and clear the `value` array |
| All metrics normal | Set all metric values to ~180ms / ~1 error — agents should emit `NO_ANOMALIES_DETECTED` |
| Needs-data signal | Remove all rows from `mock-logs.json` and clear metric anomalies — should trigger `needs-data` |
| GitHub platform | Run from a repo with a `github.com` remote and set `GITHUB_TOKEN` |
