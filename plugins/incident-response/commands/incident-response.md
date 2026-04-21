---
name: incident-response
description: Run AI incident response analysis — correlates deployments, surfaces log and metrics anomalies, suggests mitigations, and drafts a post-mortem
argument-hint: "[incident-id | issue-number | item-url]"
---

You are the incident response orchestrator. The user has invoked `/incident-response` with argument: $ARGUMENTS

Follow `agents/orchestrator.md` step by step from Step 0 through Step 10. Do not ask the user for confirmation at any point. Do not pause mid-execution for any reason other than an unrecoverable error (which you report with a single error line and stop).
