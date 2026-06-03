# Completion Report Template

This template defines the 8-section structure for the Markdown completion report produced by the `report-writer` agent. Write to `ai-dlc/code-archaeology-analysis.md`.

---

## Report Sections Overview

| # | Section | Source Agent | Notes |
|---|---|---|---|
| 1 | **Executive Summary** | orchestrator | Date, languages, module count, Bolt summary, AI-DLC readiness |
| 2 | **Module Map & Capability Map** | module-scanner | Full module list, business descriptions, capability table |
| 3 | **Service Boundaries & Integration Points** | module-scanner | Hard/soft boundaries, cross-cutting concerns, external integrations |
| 4 | **Code Patterns & Conventions** | pattern-extractor | Naming, error handling, ORM, API shapes, auth, tests, data flows |
| 5 | **Work Classification** | work-classifier | Enhancement / Remediation / Migration Bolts — confirmed by engineer |
| 6 | **Blast Radius Controls** | coverage-analyst | Test coverage baseline, feature flag status, safety net assessment |
| 7 | **Repository Overlay Files** | overlay-writer | Files written (or skip reason) |
| 8 | **Recommended Next Steps** | report-writer | Immediate actions, quick wins, AI-DLC work order |

---

## Markdown Structure

```markdown
# Code Archaeology Analysis
> **Generated:** [ISO 8601 date]
> **Target:** `[path]`
> **Plugin:** Code Archaeology Analyst v1.0.0

---

## 1. Executive Summary

| Field | Value |
|---|---|
| **Analysis Date** | [date] |
| **Target Path** | `[path]` |
| **Languages** | [comma-separated list] |
| **Frameworks** | [comma-separated list] |
| **Modules Found** | [N] ([N] application, [N] api, [N] data, [N] ui, [N] tests, etc.) |
| **Enhancement Bolts** | [N] |
| **Remediation Bolts** | [N] |
| **Migration Bolts** | [N] |
| **First Entry Point** | `[module path]` |
| **Test Coverage** | [N% / Cannot determine — manual check required] |
| **Feature Flags** | [Present ([system name]) / Not present] |
| **Overlay Files** | [Written / Skipped] |

[3–5 sentence narrative: what this codebase does, its current state (clean / has debt / in migration), and a clear statement of AI-DLC readiness]

---

## 2. Module Map & Capability Map

### All Modules

| # | Module | Path | Type | Status |
|---|--------|------|------|--------|
| 1 | [name] | `path/to/module` | [type] | ✅ Analyzed / ⚠️ Partial / ❌ Skipped |

### Module Descriptions

#### [Module Name]
**Path:** `path/to/module`
**Type:** [type]
**Description:** [business-language description — 2–4 sentences]
**Key Capabilities:**
- [capability]
- [capability]
**Consumers:** [who uses this module]

[...repeat for all modules...]

### Capability Map

| Capability | Module | Layer | User-Facing? | Critical Path? |
|---|---|---|---|---|
| [Business capability] | [module] | [layer] | Yes / No | Yes / No |

---

## 3. Service Boundaries & Integration Points

### Hard Boundaries (Separate Deployable Units)
| Unit | Path | Description |
|---|---|---|
| [name] | `path` | [description] |

### Soft Boundaries (Internal Domain Separation)
| Domain | Modules | Description |
|---|---|---|
| [domain] | `module-a`, `module-b` | [what this domain groups] |

### Cross-Cutting Concerns
| Concern | Modules | Notes |
|---|---|---|
| [Logging / Auth / Caching / Error Handling] | [list] | [implementation notes] |

### External Integrations
| External System | Module | Purpose | Protocol |
|---|---|---|---|
| [system] | `module` | [purpose] | [REST / SDK / DB / queue] |

---

## 4. Code Patterns & Conventions

### Naming Conventions
| Category | Convention | Example | Exceptions |
|---|---|---|---|
| Files | [convention] | [example] | [exceptions] |
| Functions | [convention] | [example] | — |
| Classes / Types | [convention] | [example] | — |
| Constants | [convention] | [example] | — |
| Test files | [convention] | [example] | — |
| Directories | [convention] | [example] | — |
| API routes | [convention] | [example] | — |

### Error Handling
[Summary from pattern-extractor]

### ORM / Database Usage
[Summary from pattern-extractor]

### API Shapes
[Summary from pattern-extractor]

### Auth Patterns
[Summary from pattern-extractor]

### Test Patterns
[Summary from pattern-extractor]

### Data Flows
#### Entry Points
[table]
#### Transformation Points
[table]
#### Persistence Points
[table]
#### Exit Points
[table]

### Inconsistencies Found
| Area | Inconsistency | Modules | Recommendation |
|---|---|---|---|
[rows, or "None identified"]

---

## 5. Work Classification

> ✅ All work items reviewed and confirmed by the engineer on [date].

### Enhancement Bolts ([N])
| ID | Name | Module | Description | Complexity | Risk | Blocked By |
|----|------|--------|-------------|------------|------|------------|
| E1 | [title] | `module` | [description] | [Low/Med/High] | 🔴/🟡/🟢 | — |

### Remediation Bolts ([N])
| ID | Name | Module | Description | Complexity | Risk | Evidence |
|----|------|--------|-------------|------------|------|----------|
| R1 | [title] | `module` | [description] | [Low/Med/High] | 🔴/🟡/🟢 | [evidence] |

### Migration Bolts ([N])
| ID | Name | Module | Description | Complexity | Risk | Blocked By |
|----|------|--------|-------------|------------|------|------------|
| M1 | [title] | `module` | [description] | [Low/Med/High] | 🔴/🟡/🟢 | — |

---

## 6. Blast Radius Controls

### First Entry-Point Module
- **Module:** [name] — `path`
- **Associated Bolt:** [ID]
- **Rationale:** [why selected]

### Test Coverage
[Coverage result from coverage-analyst — pass/fail counts, coverage %, or REQUIRED MANUAL CHECK notice]

### Feature Flag Assessment
[Feature flag result from coverage-analyst]

### Safety Net: [Strong / Moderate / Weak]
[Recommendation from coverage-analyst]

### Prerequisite Bolts
[List of Bolts that must be addressed before AI-DLC work starts, or "None — safe to begin"]

---

## 7. Repository Overlay Files

| File | Status | Description |
|---|---|---|
| `ai-dlc/rules/codebase-rules.md` | ✅ Written / N/A | Rules for AI assistants |
| `ai-dlc/guidelines/forbidden-zones.md` | ✅ Written / N/A | Zones requiring human oversight |
| `ai-dlc/guidelines/entry-points.md` | ✅ Written / N/A | Safe autonomous work zones |
| `ai-dlc/rules/code-standards.md` | ✅ Written / N/A | Extracted code standards |

---

## 8. Recommended Next Steps

### Immediate Actions (Complete Before Starting AI-DLC Work)
- [Required manual check or high-risk Remediation Bolt to address first]

### Quick Wins (Start Now)
- [Low-complexity, low-risk Bolt — ID, name, estimated effort]

### Suggested AI-DLC Work Order
1. [Bolt ID + name — reason for this position in the order]
2. [Bolt ID + name]
...

### How to Use the Overlay Files
Add the following references to your project's `CLAUDE.md`:
```markdown
@ai-dlc/rules/codebase-rules.md
@ai-dlc/guidelines/forbidden-zones.md
@ai-dlc/guidelines/entry-points.md
@ai-dlc/rules/code-standards.md
```
This loads all overlay files into the AI assistant's context automatically.
```

---

## Content Rules

1. Replace all `[bracketed]` placeholders with actual data from the analysis
2. If any section's source agent output is missing, render that section as: `> ⚠️ Not available — [reason]`
3. Work Classification must be preceded by the engineer confirmation note
4. REQUIRED MANUAL CHECKs must use a blockquote warning and be impossible to miss
5. Every Bolt must have an evidence citation
6. The Recommended Next Steps section must always be actionable — no vague guidance
7. Inconsistencies table must show "None identified" explicitly (never omit the row)
