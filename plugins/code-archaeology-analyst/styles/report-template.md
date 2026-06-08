# Codebase Archaeology Report Template

This template defines the exact structure of the report produced by the `report-writer` agent. Follow it exactly. Write to `ai-dlc/reports/code-archaeology-analysis.md`.

---

```markdown
# Codebase Archaeology Report

**Date:** YYYY-MM-DD
**Repository:** [name / path]
**Agent:** Code Archaeology Analyst v2.0.0
**Segments analyzed:** [N]
**Overall confidence:** High / Medium / Low

---

## Segment Map

| Segment | Scope | File count | Confidence | Notes |
|---|---|---|---|---|
| [name] | `path/to/folder/` | [N] | High / Medium / Low | [boundary notes if non-obvious] |

---

## Architecture Summary

### Capability Map

[What the system does as a whole — one paragraph in business language. No implementation detail.]

### Module Descriptions

[One entry per module, in exactly this format:]

```
Module: [name]
Purpose: [what it does in business terms — one paragraph maximum]
Owns: [what data or state it is authoritative for]
Calls: [what other modules or external services it depends on]
Exposes: [what it provides to other modules or external callers]
```

### Service Boundaries

- [Boundary rule — e.g. "Module A must not call Module C directly — all calls go through Module B"]
- [Boundary violation found in current code — if any]

### Integration Points

- [External system or cross-segment connection — what and how]

### Data Flows

- **[Entry point]:** [trigger] → [transform] → [persist] → [exit]

### Cross-Segment Dependencies

[Modules or data flows that span segment boundaries. Flag tight coupling or hidden dependencies.]

---

## Coding Conventions

[Consolidated across all segments. Where all segments agreed: Confirmed. Where they differed: Inconsistency or Split.]

| Pattern type | Convention | Status | Example |
|---|---|---|---|
| Naming | [description] | Confirmed / Inconsistency / Split | `file:line` |
| Error handling | [description] | Confirmed / Inconsistency / Split | `file:line` |
| ORM / DB access | [description] | Confirmed / Inconsistency / Split | `file:line` |
| API response shape | [description] | Confirmed / Inconsistency / Split | `file:line` |
| Authentication | [description] | Confirmed / Inconsistency / Split | `file:line` |
| Testing | [description] | Confirmed / Inconsistency / Split | `file:line` |
| Dependency wiring | [description] | Confirmed / Inconsistency / Split | `file:line` |
| Configuration | [description] | Confirmed / Inconsistency / Split | `file:line` |

### Conventions That Cannot Be Encoded Without a Human Decision

[Every Split pattern from all segments. For each, state both variants and which modules use each. A human must decide which to standardize on before coding rules are written.]

| Pattern type | Variant A | Used in | Variant B | Used in |
|---|---|---|---|---|
| [type] | [convention A] | [modules] | [convention B] | [modules] |

---

## Due Diligence Findings

### Critical

| # | Location | Category | Description | Impact if inherited | Recommendation |
|---|---|---|---|---|---|
| C1 | `file:function` | [category] | [specific description] | [what new code copying this would cause] | Fix-in-place / Quarantine / Encode as prohibition |

### High

| # | Location | Category | Description | Impact if inherited | Recommendation |
|---|---|---|---|---|---|

### Medium

| # | Location | Category | Description | Impact if inherited | Recommendation |
|---|---|---|---|---|---|

### Low

| # | Location | Category | Description | Impact if inherited | Recommendation |
|---|---|---|---|---|---|

### Findings That Cannot Be Classified Without a Human Decision

| # | Location | What was observed | Decision needed |
|---|---|---|---|

---

## Work Backlog

| # | Work item | Type | Priority | Depends on | Notes |
|---|---|---|---|---|---|
| R1 | [description specific enough to act on] | Remediation | P1 | — | [source segment / finding] |
| E1 | [description] | Enhancement | P2 | R1 | [source] |
| R2 | [description] | Remediation | P3 | — | [source] |
| M1 | [description] | Migration | P5 | R1, R2 | [source] |

### Backlog Summary

| Priority | Count | Blocks new development? |
|---|---|---|
| P1 — Must do first | [N] | Yes |
| P2 — Do early | [N] | No |
| P3 — Do alongside | [N] | No |
| P4 — Schedule | [N] | No |
| P5 — Defer | [N] | No |

---

## Recommended Next Steps

### Before any new development begins

[Every P1 item and every Critical finding with Fix-in-place recommendation. One bullet per item. This is the immediate action list.]

### Coding standards to write

[Every Confirmed convention from the Coding Conventions table. These are safe to encode as rules.]

### Items requiring a human decision before rules can be written

[Every Split pattern and every unclassifiable finding. For each: what was observed, the two options, and what decision is needed.]

### Blast radius controls to establish

Before any bolt (batch of work) executes on existing code:

1. **Test coverage gate** — verify adequate test coverage exists for the target module. If not, schedule coverage remediation first.
2. **Feature flag requirement** — every change to an existing module must be wrapped in a feature flag.
3. **Default acceptance criterion** — every bolt touching existing code must carry: *"All integration tests for [affected module] pass without modification."*
4. **Breaking Changes Register** — required for any change to API shapes, data schemas, or inter-module interfaces.

---

## Confidence Assessment

| Dimension | Level | Notes |
|---|---|---|
| Architecture mapping | High / Medium / Low | [what limited confidence, if anything] |
| Pattern extraction | High / Medium / Low | [sample size; any gaps] |
| Due diligence coverage | High / Medium / Low | [areas not fully audited] |
| Debt classification | High / Medium / Low | [ambiguities in classification] |

**Overall confidence:** [High / Medium / Low]

[Two to three sentences on what the agent is most and least confident about, and where human review would have the highest return.]

---

## Areas Not Analyzed

| Area | Reason excluded | Follow-up needed? |
|---|---|---|
| `node_modules/` | Auto-excluded — third-party | No |
| `[path]` | Configured skip / Auto-excluded / Context limit | Yes / No |

---

## Autonomous Decision Log

```
Decision Log
─────────────────────────────────────────────────────────────
[Phase] — [what decision was made] — [why]

[Phase] — [what decision was made] — [why]
─────────────────────────────────────────────────────────────
```
```
