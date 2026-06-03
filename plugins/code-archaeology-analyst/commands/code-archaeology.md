---
name: code-archaeology
description: Deep codebase archaeology analysis. Reads the codebase module by module, maps capabilities, extracts patterns and conventions, classifies work into Enhancement/Remediation/Migration Bolts, writes AI-DLC repository overlay files, checks test coverage and feature flag implementation, and delivers a completion report at ai-dlc/code-archaeology-analysis.md. Usage: /code-archaeology [path] [--no-overlay] [--no-coverage]
argument-hint: [path] [--no-overlay] [--no-coverage]
---

Run a full codebase archaeology analysis for $ARGUMENTS.

## What This Does

Invokes the **orchestrator** agent to perform systematic codebase archaeology — scanning every module, extracting patterns and conventions, classifying all identified work, writing AI-DLC overlay files, and delivering a structured completion report.

## Pipeline

```
/code-archaeology
    └── orchestrator
          │
          ├── Step 1: Initial codebase survey (structure, languages, frameworks)
          │
          ├── Phase 1 (parallel):
          │     ├── module-scanner     — module list, business descriptions, capability map
          │     └── pattern-extractor  — conventions, service boundaries, data flows
          │
          ├── Phase 2:
          │     └── work-classifier    — Enhancement / Remediation / Migration Bolts
          │                              ⏸ PAUSE: presents classification to engineer
          │
          ├── Phase 3 (parallel, after confirmation):
          │     ├── overlay-writer     — writes ai-dlc/ rule and guideline files
          │     └── coverage-analyst   — test coverage + feature flag check
          │
          └── Phase 4:
                └── report-writer  →  ai-dlc/code-archaeology-analysis.md
```

## Entry Points

| Argument | Example | What it does |
|---|---|---|
| **No argument** | `/code-archaeology` | Analyzes current working directory |
| **Path** | `/code-archaeology src/` | Analyzes the specified path |
| `--no-overlay` | `/code-archaeology --no-overlay` | Skips writing ai-dlc/ overlay files |
| `--no-coverage` | `/code-archaeology --no-coverage` | Skips test coverage and feature flag analysis |

## Agents

**Phase 1 (parallel):**

| Agent | Focus |
|---|---|
| `module-scanner` | Reads every module, writes business-language descriptions, produces capability map and service boundaries |
| `pattern-extractor` | Identifies service boundaries, integration points, data flows; extracts naming conventions, error handling, ORM usage, API shapes, auth patterns, and test patterns from 10–20 representative files |

**Phase 2:**

| Agent | Focus |
|---|---|
| `work-classifier` | Classifies all identified work into Enhancement / Remediation / Migration Bolts using Phase 1 analysis; presents the classification to the engineer for confirmation before the pipeline continues |

**Phase 3 (parallel, after engineer confirmation):**

| Agent | Focus | Skip when |
|---|---|---|
| `overlay-writer` | Writes rule file, forbidden-zones.md, entry-points.md, and code-standards.md under ai-dlc/ | `--no-overlay` |
| `coverage-analyst` | Reports test coverage for the first entry-point module; checks feature flag implementation | `--no-coverage` |

**Phase 4:**

| Agent | Focus |
|---|---|
| `report-writer` | Produces the full completion report at `ai-dlc/code-archaeology-analysis.md` |

## Output Files

| File | Description |
|---|---|
| `ai-dlc/code-archaeology-analysis.md` | Main completion report |
| `ai-dlc/rules/codebase-rules.md` | Rules for AI assistants working with this codebase |
| `ai-dlc/guidelines/forbidden-zones.md` | Areas requiring human pilot intervention |
| `ai-dlc/guidelines/entry-points.md` | Areas safe to proceed autonomously |
| `ai-dlc/rules/code-standards.md` | Extracted code standards and conventions |

## Prerequisites

- Must be run inside a git repository
- Read access to all source files in the target path

---

Starting code archaeology analysis now...
