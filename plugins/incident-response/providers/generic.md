# Generic Provider

Used when the git remote is not Azure DevOps or GitHub, or when running in offline/test mode.

## Incident Input

When the platform is Generic, the orchestrator reads the incident from one of two sources in order:

1. **File path**: if `$ARGUMENTS` is a path to an existing file (e.g., `test-data/mock-incident.md`), read its contents as the incident description.
2. **Pasted text**: prompt the user once — "Paste the incident description and press Enter twice." — then use the pasted text.

Extract the same fields from the text as any other platform: severity, start time, affected services, incident ID.

---

## Output

Write all 5 sections to `incident-response-report.md` in the current working directory, overwriting any previous report.

### File structure

```markdown
# Incident Response Report
Generated: {ISO timestamp}
Incident: {INCIDENT_ID} — {INCIDENT_TITLE}

---

## 🚨 Incident Summary
{content}

---

## 🚀 Deployment Correlation
{content}

---

## 📊 Logs & Metrics Analysis
{content}

---

## 🛠️ Mitigation Suggestions
{content}

---

## 📝 Post-Mortem Draft
{content}
```

Sections with no findings are omitted entirely.

---

## Status Signal

For Generic platform, print the status signal to stdout:

```
[incident-response] Status signal: {investigating | resolved | needs-data}
```

No label or tag is applied since there is no remote platform to update.

---

## Test Data Integration

When running against test data, point the log and metrics agents at the mock files:

```bash
export METRICS_SOURCE=plugins/incident-response/test-data/mock-metrics.json
```

Then invoke with the mock incident file:

```
/incident-response plugins/incident-response/test-data/mock-incident.md
```

See `test-data/README.md` for the full walkthrough.
