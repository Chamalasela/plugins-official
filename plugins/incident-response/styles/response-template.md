# Response Template

The orchestrator posts five comments in this exact order. Each comment is a standalone markdown block. Omit any comment entirely if the corresponding analyst returned no findings.

---

## Comment 1 — 🚨 Incident Summary

```markdown
## 🚨 Incident Summary

> AI-generated incident response — [incident-response plugin](https://github.com/xianix-team/xianix-plugins-official)

| Field | Value |
|---|---|
| **Incident** | #{incident_id} — {incident_title} |
| **Severity** | {severity} |
| **Status Signal** | `{investigating \| resolved \| needs-data}` |
| **Affected Services** | {service1}, {service2} |
| **Blast Radius Window** | {window_start} → {window_end} UTC |

**Summary:** {2–3 sentences describing what happened, what was observed, and current status. Factual and brief.}
```

---

## Comment 2 — 🚀 Deployment Correlation

```markdown
## 🚀 Deployment Correlation

Deployments completed within the blast radius window ({window_start} → {window_end} UTC):

| Deployment ID | Build / Release | Service | Completed At | Likelihood | Reason |
|---|---|---|---|---|---|
| {id} | {build_number} | {service} | {timestamp} | `likely-cause` | {one-line reason} |
| {id} | {build_number} | {service} | {timestamp} | `possible-cause` | {one-line reason} |
| {id} | {build_number} | {service} | {timestamp} | `unrelated` | {one-line reason} |

**Rollback Candidates:** {id1} ({service1}), {id2} ({service2})
```

Omit the "Rollback Candidates" line if there are none. If no deployments were found in the window, omit this comment entirely.

---

## Comment 3 — 📊 Logs & Metrics Analysis

```markdown
## 📊 Logs & Metrics Analysis

**First Anomaly Detected:** {timestamp} UTC
**Baseline Error Rate:** ~{n} errors / 5-min bucket (measured {window_start} → {window_start+30min})

### Log Findings
| Time (UTC) | Exception Type | Count | Note |
|---|---|---|---|
| {time} | {ExceptionType} | {count} | Peak error bucket |
| {time} | {ExceptionType} | {count} | Onset — matches deployment window |

**HTTP 5xx Spike:** {operation} — {count} failures at {time}
**Latency:** {operation} P95 reached {value}ms at {time} (baseline: ~{baseline}ms)

### Metrics Findings
| Metric | Baseline | Peak | First Detected |
|---|---|---|---|
| Error Rate | ~{baseline}% | {peak}% | {timestamp} |
| Avg Response Time | ~{baseline}ms | {peak}ms | {timestamp} |
| CPU | normal | {peak}% | {timestamp} |

**Trend at window end:** {escalating \| stabilising \| recovering}
```

Omit subsections (Log Findings / Metrics Findings) if the corresponding source was unavailable. Add a one-line note at the end of the comment if a source was missing: `*Log data unavailable — set LOG_ANALYTICS_WORKSPACE_ID to enable KQL queries.*`

---

## Comment 4 — 🛠️ Mitigation Suggestions

```markdown
## 🛠️ Mitigation Suggestions

**Root Cause Confidence:** {high \| medium \| low \| insufficient}
**Assessment:** {one sentence from mitigation advisor — e.g., "Deployment 8821 introduced a DB connection pool configuration change that caused cascading timeouts in payment-service."}

### Immediate Actions
1. {action — present tense, specific}
2. {action}

### Rollback
- **Deployment {id}** — {service} build `{build_number}` deployed at {timestamp}
  ```
  {rollback command or instruction}
  ```

### Config Hints
- {hint}

### Containment
- {action}
```

Omit any subsection (Rollback, Config Hints, Containment) if there is nothing to put under it. Always include at least one Immediate Action.

---

## Comment 5 — 📝 Post-Mortem Draft

```markdown
## 📝 Post-Mortem Draft

> This is an AI-generated starting point. Times marked *(inferred)* should be verified against actual logs and deployment records before the post-mortem meeting.

### Timeline

| Time (UTC) | Event | Source |
|---|---|---|
| {timestamp} | Deployment {id} ({service} `{version}`) completed | Pipeline |
| {timestamp} | First log anomaly — {exception_type} count begins rising | Log Analytics |
| {timestamp} | Error rate crosses 2× baseline | Metrics |
| {timestamp} | Incident "{title}" opened | Incident Report |
| {timestamp} *(inferred)* | On-call engineer begins investigation | Inferred |

### Contributing Factors
- {neutral observation}
- {neutral observation}

### Action Items *(discussion prompts for the team)*
- [ ] {prompt}
- [ ] {prompt}
- [ ] {prompt}
```
