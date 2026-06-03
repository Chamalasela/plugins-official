# Code Archaeology Analyst

Deep codebase archaeology analysis plugin. Performs a systematic, phase-by-phase analysis of any codebase — scanning every module, extracting patterns and conventions, classifying all identified work, writing AI-DLC repository overlay files, and delivering a structured completion report.

Implements the Phase M1 setup guide workflow for AI-DLC onboarding.

---

## Quick Start

```bash
# Analyze the current directory
/code-archaeology

# Analyze a specific path
/code-archaeology src/

# Skip writing overlay files
/code-archaeology --no-overlay

# Skip test coverage and feature flag analysis
/code-archaeology --no-coverage

# Fast run — analysis only, no side effects
/code-archaeology --no-overlay --no-coverage
```

---

## Pipeline

```
/code-archaeology
    └── orchestrator
          │
          ├── Step 1: Initial codebase survey
          │           (structure, languages, frameworks, recent commits)
          │
          ├── Phase 1 (parallel):
          │     ├── module-scanner     — reads every module, writes business descriptions,
          │     │                         produces capability map, identifies service boundaries
          │     └── pattern-extractor  — extracts naming conventions, error handling,
          │                             ORM usage, API shapes, auth patterns, test patterns,
          │                             data flows, and inconsistencies
          │
          ├── Phase 2:
          │     └── work-classifier    — classifies all work into Enhancement /
          │                             Remediation / Migration Bolts
          │                             ⏸ PAUSE: presents to engineer for confirmation
          │
          ├── Phase 3 (parallel, after confirmation):
          │     ├── overlay-writer     — writes ai-dlc/ rule and guideline files
          │     └── coverage-analyst   — reports test coverage + feature flag assessment
          │
          └── Phase 4:
                └── report-writer  →  ai-dlc/code-archaeology-analysis.md
```

---

## Agents

| Agent | Phase | Role |
|---|---|---|
| `orchestrator` | All | Coordinates all phases, handles user confirmation at Phase 2 |
| `module-scanner` | 1 (parallel) | Enumerates every module; writes business-language descriptions; produces capability map and service boundary analysis |
| `pattern-extractor` | 1 (parallel) | Reads 10–20 representative files; extracts naming, error handling, ORM, API, auth, test patterns; maps data flows; flags inconsistencies |
| `work-classifier` | 2 | Classifies all identified work into Enhancement / Remediation / Migration Bolts with evidence |
| `overlay-writer` | 3 (parallel) | Writes four AI-DLC overlay files under `ai-dlc/` |
| `coverage-analyst` | 3 (parallel) | Runs test suite for first entry-point module; assesses feature flag implementation |
| `report-writer` | 4 | Produces the 8-section completion report |

---

## Report Structure (8 sections)

| # | Section | Notes |
|---|---|---|
| 1 | **Executive Summary** | AI-DLC readiness at a glance |
| 2 | **Module Map & Capability Map** | Every module with business description |
| 3 | **Service Boundaries & Integration Points** | Architecture overview |
| 4 | **Code Patterns & Conventions** | Naming, errors, ORM, API, auth, tests, data flows |
| 5 | **Work Classification** | Enhancement / Remediation / Migration Bolts — engineer-confirmed |
| 6 | **Blast Radius Controls** | Test coverage baseline, feature flag status, safety net |
| 7 | **Repository Overlay Files** | List of files written |
| 8 | **Recommended Next Steps** | Prioritized AI-DLC work order |

---

## Work Classification: Bolt Types

| Bolt | Meaning | Example |
|---|---|---|
| **Enhancement** | New functionality the codebase is ready to receive | Add OAuth login, add a new API endpoint |
| **Remediation** | Fix issues, improve quality, reduce debt | Fix a bug, add missing tests, resolve a security issue |
| **Migration** | Move or transform existing functionality | Migrate to a new library, refactor module structure |

Each Bolt includes: ID, Name, Module, Description, Complexity (Low/Medium/High), Risk (🔴/🟡/🟢), and Evidence.

---

## Output Files

| File | Description |
|---|---|
| `ai-dlc/code-archaeology-analysis.md` | Main completion report |
| `ai-dlc/rules/codebase-rules.md` | Directive rules for AI assistants — Always/Never/When |
| `ai-dlc/guidelines/forbidden-zones.md` | Areas requiring human pilot intervention |
| `ai-dlc/guidelines/entry-points.md` | Areas safe for autonomous AI work |
| `ai-dlc/rules/code-standards.md` | Extracted code standards with examples |

---

## Flags

| Flag | Effect |
|---|---|
| `--no-overlay` | Skip writing all `ai-dlc/` overlay files |
| `--no-coverage` | Skip test coverage analysis and feature flag check |

---

## Key Design Decisions

- **Engineer confirmation gate** — the orchestrator pauses after Phase 2 and presents the work classification to the engineer. Phase 3 only starts after confirmation. This ensures human oversight of all AI-DLC planning decisions.
- **Parallel Phase 1** — `module-scanner` and `pattern-extractor` run simultaneously to minimize analysis time
- **Parallel Phase 3** — `overlay-writer` and `coverage-analyst` run simultaneously after confirmation
- **Budget warnings** — all Phase 1 agents emit explicit warnings if their tool call budget is reached, so coverage gaps are visible
- **REQUIRED MANUAL CHECK** — if tests cannot be run, the coverage-analyst flags this prominently and blocks the entry point until resolved manually
- **Directive overlay files** — the overlay files use "Always/Never" language so AI assistants can follow them precisely without interpretation

---

## Prerequisites

- Must be run inside a git repository
- Read access to all source files in the target path
- No external API tokens required (unlike impact-analyst)
