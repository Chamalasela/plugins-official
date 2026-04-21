# Incident Sources

How the incident-response plugin reads logs, metrics, and deployment data.

---

## Log Analytics (Azure Monitor)

The log-analyzer agent runs three KQL queries against your Azure Monitor Log Analytics workspace.

### Finding your Workspace ID

1. Azure Portal → **Log Analytics workspaces** → select your workspace
2. **Overview** tab → copy **Workspace ID** (the GUID, e.g. `a1b2c3d4-...`)
3. Set: `export LOG_ANALYTICS_WORKSPACE_ID="{workspace-id}"`

### KQL Patterns Used

**Exception counts by type (5-minute buckets):**
```kql
AppExceptions
| where TimeGenerated between(datetime('2024-03-15T12:30:00Z') .. datetime('2024-03-15T15:00:00Z'))
| summarize ErrorCount=count() by bin(TimeGenerated, 5m), ExceptionType
| order by TimeGenerated asc
```

**HTTP 5xx failures by operation:**
```kql
AppRequests
| where TimeGenerated between(datetime('2024-03-15T12:30:00Z') .. datetime('2024-03-15T15:00:00Z'))
| where ResultCode >= 500
| summarize FailCount=count() by bin(TimeGenerated, 5m), Name, ResultCode
| order by TimeGenerated asc
```

**P95/P99 latency by operation:**
```kql
AppRequests
| where TimeGenerated between(datetime('2024-03-15T12:30:00Z') .. datetime('2024-03-15T15:00:00Z'))
| summarize P95=percentile(DurationMs, 95), P99=percentile(DurationMs, 99), RequestCount=count() by bin(TimeGenerated, 5m), Name
| order by TimeGenerated asc
```

### Customising KQL Queries

If your application uses custom table names (e.g., `MyApp_CL` instead of `AppExceptions`), edit `agents/log-analyzer.md` to replace the table names. The structure of the queries (summarize, bin, order) remains the same.

### Testing Without az CLI

If you don't have `az` CLI or a Log Analytics workspace, you can test by providing a pre-queried JSON file:

```bash
export METRICS_SOURCE=plugins/incident-response/test-data/mock-logs.json
```

The log-analyzer will read this file instead of running KQL queries. See `test-data/mock-logs.json` for the expected format.

---

## Metrics (Azure Monitor)

### Fetching a Metrics Snapshot

```bash
# Find your resource ID
az resource list --query "[?contains(name, 'payment-service')]" --output table

# Export metrics to a JSON file
az monitor metrics list \
  --resource "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Web/sites/payment-service" \
  --metric "Requests" "Http5xx" "AverageResponseTime" "CpuPercentage" \
  --start-time "2024-03-15T12:30:00Z" \
  --end-time "2024-03-15T15:00:00Z" \
  --interval PT1M \
  --output json > metrics-snapshot.json
```

### Using a Metrics Snapshot File

```bash
export METRICS_SOURCE=metrics-snapshot.json
```

When `METRICS_SOURCE` is set, the metrics-analyzer reads the file directly and skips the `az monitor metrics list` call. This is the recommended approach for:
- Testing with mock data
- Re-running analysis after the fact (when the live window has passed)
- Environments without `az` CLI access

### Expected JSON Format

The file should match the output of `az monitor metrics list --output json`. See `test-data/mock-metrics.json` for a complete example with annotated structure.

---

## Deployment History

### Azure DevOps

Deployments are queried from two APIs:
1. **Build API** — captures pipeline runs (includes CD pipelines that deploy directly)
2. **Release API** — captures classic release pipeline deployments

Both are queried for the blast radius window. If your organization uses only one deployment model, only that API will return results; the other returns an empty list (not an error).

### GitHub

Deployment history is read from **GitHub Actions workflow runs** via the `gh api` command. The agent looks at all runs that completed within the blast radius window, regardless of workflow name — then tags each based on which repository/service it affected.

If your deployment workflows follow a naming convention (e.g., "Deploy to production — payment-service"), this naming is used to improve the service-overlap matching in the tagging logic.

---

## Generic / Offline Mode

For testing or when no platform is configured:

1. Write the incident to `test-data/mock-incident.md`
2. Set `METRICS_SOURCE` to a mock metrics file
3. Run: `/incident-response test-data/mock-incident.md`
4. Output is written to `incident-response-report.md`

See `test-data/README.md` for a complete walkthrough using the sample payment-service incident.
