---
name: correlate-deployments
description: Query deployment history for an incident window and tag each deployment as likely-cause, possible-cause, or unrelated
argument-hint: "[incident-id | issue-number]"
disable-model-invocation: true
---

Run /incident-response $ARGUMENTS --phase deployment
