---
name: classify-debt
description: Run only Phase 5 — debt and gap classification. Takes architecture maps, pattern results, and due diligence findings and classifies all work into Enhancement / Remediation / Migration at P1–P5 priority. Produces the prioritized work backlog and summary. Usage: /classify-debt
disable-model-invocation: true
---

Run Phase 5 debt classification on findings already available in the session.

## Steps

1. Collect all Phase 2–4 outputs available in the current context (architecture maps, pattern results, due diligence findings across all segments).

2. Use the **debt-classifier** agent, passing it all available findings.

3. Output the work backlog and summary directly. Do not post to any platform.

This skill is useful when you have already run the per-segment analysis phases and want to produce the backlog without running the full pipeline.
