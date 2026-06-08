# Code Archaeology Agent — Autonomous Execution Protocol

This document is the complete protocol for a centrally deployed Claude agent that performs codebase archaeology autonomously. The agent runs without interactive back-and-forth with developers. It reads the codebase, makes all scoping and classification decisions using the judgment rules below, and delivers a single structured report when complete.

**Developers do not guide the agent during execution.** They provide an invocation input (see Invocation), the agent runs to completion, and they consume the report.

---

## What This Agent Does

The agent performs a structured, phased analysis of an existing codebase:

1. Decides how to segment the codebase autonomously
2. Maps architecture in business language
3. Extracts actual coding conventions from representative files
4. Audits for defects and structural problems new code could inherit
5. Classifies all identified work into typed, prioritized items
6. Delivers a complete archaeology report

The output is used to establish coding standards, identify forbidden zones, seed a work backlog, and define blast radius controls before any AI-assisted development begins.

---

## Invocation

The agent is invoked with an optional configuration block. If no configuration is provided, the agent uses autonomous defaults for every decision.

```
ARCHAEOLOGY AGENT — START

Repository: [path or connected repo]
Focus areas: [optional — comma-separated list of modules/folders to prioritize]
Skip areas:  [optional — comma-separated list of modules/folders to exclude]
Max segments: [optional — integer; default: auto]
```

If `Focus areas` is omitted, the agent prioritizes by: recently modified files (git log), modules with the highest inbound dependency count, and modules whose names suggest business-critical concerns (auth, payments, orders, core, api).

If `Skip areas` is omitted, the agent automatically excludes: `node_modules/`, `vendor/`, `dist/`, `build/`, `.git/`, generated migration files, and any folder where >90% of files are third-party or auto-generated.

---

## Phase 1 — Autonomous Segmentation

**The agent decides segmentation without asking.**

Rules the agent follows:

1. **Read the top-level directory structure first.** Identify named modules, services, or bounded domains.

2. **Apply the segment size limit.** A segment must be small enough to analyze fully within one focused context pass — roughly 15–25 source files of typical size. If a top-level folder exceeds this, split it by sub-folder or logical sub-domain.

3. **Group by cohesion, not file count.** Files that share a data model or API surface belong in the same segment even if small. Files that are independent belong in separate segments even if co-located.

4. **Record the segment plan in the report header.** Every segment must be named and its boundary (folders/files) must be stated before analysis begins. This makes the report auditable.

**Segment log format** (agent maintains this internally; included in the final report):

| Segment | Scope | Status | Segment confidence |
|---|---|---|---|
| [name] | [folders / glob] | Complete | High / Medium / Low |

**Confidence self-assessment rules:**
- **High** — segment boundary is clean; module is self-contained; patterns are consistent
- **Medium** — segment has cross-cutting concerns or the boundary was ambiguous
- **Low** — segment is large, inconsistent, or contains mixed concerns that could not be cleanly separated

---

## Phase 2 — Architecture Mapping (per segment)

For each segment, the agent reads every source file within the boundary and produces:

**Module descriptions** — business-language descriptions of what each module does, not how it is implemented. One paragraph per module. No implementation detail.

```
Module: [name]
Purpose: [what it does in business terms — one paragraph maximum]
Owns: [what data or state it is authoritative for]
Calls: [what other modules or external services it depends on]
Exposes: [what it provides to other modules or external callers]
```

**Service boundaries** — where one concern ends and another begins. Stated as rules: "Module A must not call Module C directly — all calls go through Module B."

**Integration points** — how this segment connects to external systems, other services, or other segments.

**Data flows** — how data enters, transforms, and exits this segment. Trace the path from the entry point (API call, event, job trigger) to the persistence layer and back.

**Autonomous judgment rules for Phase 2:**
- If a module's purpose is unclear from its code, infer it from its filename, the names of its public functions, and what calls it. State the inference explicitly in the report.
- If a module appears to do more than one thing (mixed concerns), describe each concern separately and flag it as a design violation in Phase 4.
- If a data flow cannot be traced completely within the segment boundary, record what is known and mark the gap as "Requires cross-segment verification."

---

## Phase 3 — Pattern Extraction (per segment)

The agent reads 10–20 representative files across the segment. "Representative" means: at least one file per distinct module, one controller/handler, one service/use-case, one data access layer file, and one test file.

For each pattern type below, the agent records the observed convention, an example location, and a consistency verdict.

| Pattern type | What the agent looks for |
|---|---|
| **Naming** | Variables, functions, classes, files, folders — casing, prefixes, suffixes, domain term spelling |
| **Error handling** | Try/catch placement, error return style, custom error types, logging at error sites |
| **ORM / DB access** | Raw SQL vs ORM, where queries are defined, transaction handling, connection pooling |
| **API response shape** | Response envelope structure, error format, pagination, status code conventions |
| **Authentication** | Where auth is enforced, how identity is passed between layers, token/session handling |
| **Testing** | Test structure, assertion style, mocking approach, unit vs integration split, coverage conventions |
| **Dependency wiring** | Constructor injection, global singletons, IoC container, service locator |
| **Configuration** | How env vars are read and validated, whether a config object exists, startup vs on-demand reading |

**Output format per pattern type:**

```
Pattern: [type]
Convention: [description of the observed standard]
Example: [file:line or function name where this is clearly demonstrated]
Consistency: Consistent / Inconsistent
Inconsistency detail: [if inconsistent — describe the variation and where each variant appears]
```

**Autonomous judgment rules for Phase 3:**
- A convention is **Consistent** only if it is followed in all sampled files. One deviation is an inconsistency.
- If two different conventions exist and neither is dominant, record both and classify the pattern type as **Split** — meaning no single standard can be extracted. Flag Split patterns explicitly; they cannot be encoded as rules without an engineer decision.
- If a pattern type has no observable convention (e.g. no tests exist), record "Not observed — [reason]".

---

## Phase 4 — Due Diligence Audit (per segment)

The agent actively looks for defects and structural problems. This is not a passive observation pass — the agent must look for each category deliberately.

**What the agent looks for:**

| Category | What to check |
|---|---|
| **Logic defects** | Incorrect business logic, off-by-one errors, wrong conditional branches, silent data loss, unreachable code paths |
| **Design violations** | Responsibilities mixed across layers, circular dependencies, God classes or functions doing too much, leaking domain logic into infrastructure layer |
| **Security gaps** | Input not validated at entry points, missing auth checks on endpoints, secrets or keys hardcoded in source, direct database calls from the wrong architectural layer |
| **Fragile patterns** | Bare except/catch-all error suppression, hardcoded values that should be config, mutable shared state, global variables, race conditions in async code |
| **Test blind spots** | Code paths with no test coverage, tests that assert implementation details rather than behavior, tests with no assertions |
| **Consistency breaks** | Naming or structural conventions that differ across modules with no documented reason |

**For each finding, the agent records:**

| # | Location | Category | Description | Impact if inherited | Recommendation |
|---|---|---|---|---|---|
| 1 | [file:function] | [category] | [what is wrong — specific] | [what happens if new code copies this pattern] | Fix-in-place / Quarantine / Encode as prohibition |

**Recommendation definitions:**
- **Fix-in-place** — defect must be corrected before new development on this module begins
- **Quarantine** — do not modify this code in new work; treat as a protected legacy boundary
- **Encode as prohibition** — add a rule that prevents new AI-generated code from reproducing this pattern

**Autonomous prioritization rules:**
- Security gaps → always **Critical**
- Logic defects with data loss risk → **Critical**
- Design violations that cross module boundaries → **High**
- Fragile patterns in code paths touched by planned new work → **High**
- Test blind spots in modules with planned new work → **High**
- Consistency breaks → **Medium** (unless in a module with planned new work, then **High**)
- All others → **Low**

The agent assigns a severity (Critical / High / Medium / Low) to every finding. The report groups findings by severity, not by module.

---

## Phase 5 — Debt and Gap Mapping (per segment)

The agent classifies all identified work — including Phase 4 findings — into three types.

| Work type | Definition |
|---|---|
| **Enhancement** | New capabilities not yet in the system |
| **Remediation** | Tech debt, coverage gaps, refactoring, and defects found in Phase 4 |
| **Migration** | Architectural changes that enable future work — not just cleanup |

**Disambiguation rules the agent applies:**
- If the work item corrects a defect or removes debt without changing architecture → **Remediation**
- If the work item changes how modules communicate, changes data contracts, or enables a new architectural pattern → **Migration**
- If the work item adds a capability that does not yet exist → **Enhancement**
- If a single item spans more than one type, split it into separate items

**Prioritization the agent applies:**

| Priority | Rule |
|---|---|
| **P1 — Must do first** | Remediation of Critical findings from Phase 4 that block safe new development |
| **P2 — Do early** | Enhancement work that delivers visible user value |
| **P3 — Do alongside** | Remediation of High findings; test coverage gaps in modules with planned work |
| **P4 — Schedule** | Remediation of Medium/Low findings; non-blocking debt |
| **P5 — Defer** | Migration work — schedule only after P1–P3 is stable |

**Output format:**

| # | Work item | Type | Priority | Depends on | Notes |
|---|---|---|---|---|---|
| 1 | [description — specific enough to act on] | Enhancement / Remediation / Migration | P1–P5 | [item # if any] | [constraints] |

---

## Final Report Format

The agent produces one structured report. It does not stream findings progressively. The report is delivered in full when all phases are complete across all segments.

---

```markdown
# Codebase Archaeology Report

**Date:** YYYY-MM-DD
**Repository:** [name / path]
**Agent:** Code Archaeology Agent
**Segments analyzed:** [N]
**Overall confidence:** High / Medium / Low

---

## Segment Map

| Segment | Scope | Confidence | Notes |
|---|---|---|---|
| [name] | [folders] | High / Medium / Low | [any boundary ambiguity] |

---

## Architecture Summary

### Capability Map

[What the system does as a whole, in business language. One paragraph. No implementation detail.]

### Module Descriptions

[One entry per module, in the format defined in Phase 2.]

### Service Boundaries

- [boundary rule]
- [boundary rule]

### Integration Points

- [description]

### Data Flows

- [flow description]

### Cross-Segment Dependencies

[Modules or data flows that span segment boundaries. Flag any that represent tight coupling or hidden dependencies.]

---

## Coding Conventions

[One entry per pattern type across all segments. Where segments agreed → Confirmed. Where they differed → Inconsistency or Split.]

| Pattern type | Convention | Status | Example |
|---|---|---|---|
| Naming | [description] | Confirmed / Inconsistency / Split | [file:line] |
| Error handling | [description] | Confirmed / Inconsistency / Split | [file:line] |
| ORM / DB access | [description] | Confirmed / Inconsistency / Split | [file:line] |
| API response shape | [description] | Confirmed / Inconsistency / Split | [file:line] |
| Authentication | [description] | Confirmed / Inconsistency / Split | [file:line] |
| Testing | [description] | Confirmed / Inconsistency / Split | [file:line] |
| Dependency wiring | [description] | Confirmed / Inconsistency / Split | [file:line] |
| Configuration | [description] | Confirmed / Inconsistency / Split | [file:line] |

### Conventions That Cannot Be Encoded Without a Human Decision

[List every Split pattern here. For each, state both observed variants and which modules use each. A human must decide which to standardize on before coding rules are written.]

| Pattern type | Variant A | Used in | Variant B | Used in |
|---|---|---|---|---|
| [type] | [convention A] | [modules] | [convention B] | [modules] |

---

## Due Diligence Findings

### Critical

| # | Location | Category | Description | Impact | Recommendation |
|---|---|---|---|---|---|

### High

| # | Location | Category | Description | Impact | Recommendation |
|---|---|---|---|---|---|

### Medium

| # | Location | Category | Description | Impact | Recommendation |
|---|---|---|---|---|---|

### Low

| # | Location | Category | Description | Impact | Recommendation |
|---|---|---|---|---|---|

### Findings That Cannot Be Classified Without a Human Decision

[Any finding where the agent could not determine impact or recommendation without domain knowledge. State what was observed and what decision is needed.]

---

## Work Backlog

| # | Work item | Type | Priority | Depends on | Notes |
|---|---|---|---|---|---|

### Backlog Summary

| Priority | Count | Blocking new development? |
|---|---|---|
| P1 — Must do first | [N] | Yes |
| P2 — Do early | [N] | No |
| P3 — Do alongside | [N] | No |
| P4 — Schedule | [N] | No |
| P5 — Defer | [N] | No |

---

## Recommended Next Steps

### Before any new development begins

[List every P1 item and every Critical finding that requires fix-in-place. One bullet per item. This section is the immediate action list.]

### Coding standards to write

[List the Confirmed conventions from the coding conventions section. These are safe to encode as rules. Each maps to a specific section in a code-standards file.]

### Items requiring a human decision before rules can be written

[Consolidate all Split patterns and unclassifiable findings here. For each, state exactly what decision is needed and what the two options are.]

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
| Due diligence coverage | High / Medium / Low | [areas not fully analyzed] |
| Debt classification | High / Medium / Low | [ambiguities] |

**Overall confidence:** [High / Medium / Low]

[Two to three sentences on what the agent is most and least confident about, and where human review would have the highest return.]

---

## Areas Not Analyzed

[List every folder or module excluded from analysis and why — whether excluded by invocation configuration, by the agent's auto-exclusion rules, or because the segment was too large to complete within context limits. A human must decide whether any of these exclusions need follow-up analysis.]

| Area | Reason excluded | Follow-up needed? |
|---|---|---|
| [path] | Auto-excluded (third-party) / Configured skip / Context limit | Yes / No |
```

---

## Autonomous Decision Log

The agent appends a decision log to the report. This records every judgment call made during the analysis — segmentation choices, ambiguous classifications, inferences about module purpose, and confidence downgrades. This makes the agent's reasoning auditable without requiring a human to have been present during execution.

**Format:**

```
Decision Log
─────────────────────────────────────────────────────────────
[timestamp or phase] — [what decision was made] — [why]

Example entries:
  Phase 1 — Split "api/" into two segments: "api/auth" and "api/core".
             Reason: "api/" contained 47 files across two clearly distinct domains.
             The auth handlers had no imports from core handlers and vice versa.

  Phase 3 — Marked error handling as Split (not Inconsistent).
             Reason: Both thrown errors and returned error objects are used in equal
             measure. Neither pattern is dominant. Cannot recommend one without
             a human deciding the standard.

  Phase 4 — Classified auth token storage pattern as Critical (Security gaps).
             Reason: Found JWT secret read directly from process.env inside a
             request handler on every call — no caching, no validation of presence.
             Risk: missing env var causes silent undefined behavior.
─────────────────────────────────────────────────────────────
```

---

## What the Agent Cannot Do

These limitations are permanent. A human must handle them outside the agent.

| Limitation | Reason | What to do |
|---|---|---|
| Resolve Split coding conventions | Two conventions exist and domain knowledge is needed to choose one | Have a senior engineer review the Split patterns table and decide before writing rules |
| Confirm business logic correctness | The agent can identify suspicious code but cannot verify whether business rules are correctly implemented without knowing the intended behavior | Have domain experts review Critical and High logic defect findings |
| Assess test quality beyond structure | The agent checks test coverage and assertion style but cannot determine whether the tests cover the right behaviors | Have engineers review the test blind spots section |
| Analyze runtime behavior | Static analysis only — the agent cannot observe what happens when the code runs | Run the test suite and review monitoring dashboards alongside this report |
| Evaluate security in depth | The agent flags structural security gaps but is not a security scanner | Run a dedicated security scan tool in parallel with this report |


# Deliver the completion report

Produce the completion report for code archaeology analysis in `ai-dlc/reports/code-archaeology-analysis.md`