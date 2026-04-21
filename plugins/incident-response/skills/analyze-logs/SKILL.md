---
name: analyze-logs
description: Query Azure Monitor Log Analytics for error spikes, exception traces, and latency anomalies within the incident blast radius window
argument-hint: "[incident-id | issue-number]"
disable-model-invocation: true
---

Run /incident-response $ARGUMENTS --phase logs
