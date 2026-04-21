# Mock Incident — INC-4821

**Incident ID:** INC-4821
**Title:** Payment service returning 503s — elevated latency and errors
**Severity:** SEV-2
**Start Time:** 2024-03-15T14:30:00Z
**Affected Services:** payment-service, order-fulfillment-service
**Reported By:** On-call engineer (paged by Azure Monitor alert at 14:47 UTC)

## Description

Users are reporting failed payments across all regions. The API gateway is logging 503 responses from `payment-service`. Transaction success rate has dropped from 99.8% to ~88% over the past 20 minutes.

Observed symptoms:
- P95 API latency on `/api/payments/checkout` has risen from ~180ms to ~2400ms
- Error rate has jumped from ~0.1% to ~12%
- `order-fulfillment-service` is experiencing secondary failures because payment authorizations are timing out
- No recent infra changes (no scaling events, no config changes reported by SRE team)

## Initial Investigation Notes

The SRE team noted that a new release of `payment-service` (v2.4.1) was deployed approximately 45 minutes before the alert fired. The release included database schema changes for the new loyalty points feature. No automated rollback was triggered.

The team is currently investigating whether the schema migration is causing connection pool exhaustion.

## Current Status

OPEN — root cause under investigation. Mitigation not yet confirmed.
