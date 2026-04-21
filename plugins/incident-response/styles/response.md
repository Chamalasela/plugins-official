# Response Style Guide

All five incident response comments must follow this tone and style.

---

## Tone

- **Calm and factual** — never alarmist, never catastrophizing. The team is already stressed; the output should reduce cognitive load, not add to it.
- **Action-oriented** — every section should leave the reader with a clear next step or a clear question to investigate.
- **Precise** — use exact timestamps, deployment IDs, error counts, and latency values. Avoid vague phrases like "significantly higher" or "around that time."
- **Brief** — each comment should be scannable in under 60 seconds. Use tables and bullet points. Avoid prose paragraphs.

---

## Framing Rules

- **Post-mortem items are discussion prompts, not accusations.** Never write "the developer caused" or "the team failed to." Write "consider adding" or "question for the team."
- **Findings are observations, not verdicts.** A `likely-cause` tag means timing and service overlap are consistent with causation — not that causation is proven.
- **Skip sections with no findings.** If a section has nothing to say, omit it entirely. Never write "None identified," "No data available," or "N/A."
- **Never modify the incident description.** All output is posted as comments only.

---

## Status Signals

| Signal | When to use |
|---|---|
| `investigating` | At least one deployment tagged `likely-cause` or `possible-cause`, but root cause not confirmed with certainty |
| `resolved` | Root cause identified (high-confidence from mitigation advisor) AND at least one concrete mitigation action confirmed |
| `needs-data` | Insufficient signal from all three Phase 1 analysts — log source unavailable, metrics unavailable, and no deployments found |

---

## Emoji Usage

Use the following emojis exactly as specified in the response template — they aid quick scanning in issue trackers:

| Emoji | Section |
|---|---|
| 🚨 | Incident Summary |
| 🚀 | Deployment Correlation |
| 📊 | Logs & Metrics Analysis |
| 🛠️ | Mitigation Suggestions |
| 📝 | Post-Mortem Draft |

Do not add emojis beyond what is in the template.

---

## Data Quality Notes

When data is partial (e.g., log source available but metrics unavailable), still post the sections that have data. Note within that section what was unavailable and what env var or step would resolve it — one line, at the end of the section.
