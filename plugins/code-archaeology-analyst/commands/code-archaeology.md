---
name: code-archaeology
description: Deep codebase archaeology analysis triggered by a GitHub issue or Azure DevOps work item tagged 'code-archaeology'. Fetches the issue, scans the codebase module by module, extracts patterns, classifies work into Enhancement/Remediation/Migration Bolts, writes AI-DLC overlay files, and posts the full analysis back as ordered comments on the originating issue or work item. Usage: /code-archaeology [issue <n> | wi <id>] [--no-overlay] [--no-coverage]
argument-hint: [issue <n> | wi <id>] [--no-overlay] [--no-coverage]
---

Run a full codebase archaeology analysis for $ARGUMENTS.

## What This Does

Invokes the **orchestrator** agent. It detects the hosting platform, fetches the issue or work item that triggered the request, posts an "Analysis in Progress" comment immediately, runs the full four-phase analysis pipeline, and delivers the results as ordered comments on the originating issue — plus writing AI-DLC overlay files to the repository.

## Triggering the Analysis

Create a GitHub Issue (or Azure DevOps Work Item) with the `code-archaeology` label/tag. The issue body may optionally specify:

```markdown
**Target path:** src/payments          (optional — defaults to repo root)
**Modules of interest:** src/auth, src/users   (optional — defaults to all)

Any additional context or notes about what to focus on.
```

Then run:

```
/code-archaeology issue 42
/code-archaeology wi 1023
```

## Pipeline

```
/code-archaeology issue 42
    └── orchestrator
          │
          ├── Step 0: Detect platform (GitHub / Azure DevOps / Generic)
          ├── Step 1: Fetch issue #42 — parse target path and context
          ├── Step 2: Post "Analysis in Progress" comment
          ├── Step 3: Initial codebase survey (structure, languages, frameworks)
          │
          ├── Phase 1 (parallel):
          │     ├── module-scanner     — modules, descriptions, capability map
          │     └── pattern-extractor  — conventions, patterns, data flows
          │
          ├── Phase 2:
          │     └── work-classifier    — Enhancement / Remediation / Migration Bolts
          │
          ├── Post comments 1–3: Module Map | Patterns | Work Classification
          │
          ├── Phase 3 (parallel):
          │     ├── overlay-writer     — writes ai-dlc/ overlay files
          │     └── coverage-analyst   — test coverage + feature flag check
          │
          ├── Phase 4:
          │     └── report-writer  →  ai-dlc/code-archaeology-analysis.md
          │
          └── Post comments 4–5: Blast Radius Controls | Analysis Complete
                + Apply 'archaeology-complete' label
```

## Entry Points

| Argument | Example | What the agent resolves |
|---|---|---|
| `issue <n>` | `/code-archaeology issue 42` | GitHub issue #42 — reads body for target path and context |
| `wi <id>` | `/code-archaeology wi 1023` | Azure DevOps work item — reads description for target path and context |

## Flags

| Flag | Effect |
|---|---|
| `--no-overlay` | Skip writing `ai-dlc/` overlay files |
| `--no-coverage` | Skip test coverage and feature flag analysis |

## Comment Thread Posted

| # | Comment heading | Source |
|---|---|---|
| 1 | `Analysis in Progress` | Orchestrator (immediate) |
| 2 | `🗺️ Module Map & Capability Map` | module-scanner |
| 3 | `🔍 Code Patterns & Conventions` | pattern-extractor |
| 4 | `📋 Work Classification` | work-classifier |
| 5 | `🛡️ Blast Radius Controls` | coverage-analyst (skipped with `--no-coverage`) |
| 6 | `✅ Analysis Complete` | Orchestrator (summary + next steps) |

Comments with no meaningful findings are skipped.

## Platform Support

| Remote URL | Platform | Delivery |
|---|---|---|
| `github.com` | GitHub | Ordered comments via `gh` CLI + `archaeology-complete` label |
| `dev.azure.com` / `visualstudio.com` | Azure DevOps | Ordered comments via REST API + `archaeology-complete` tag |
| Anything else | Generic | Report written to `ai-dlc/code-archaeology-analysis.md` only |

## Output Files (always written to disk)

| File | Description |
|---|---|
| `ai-dlc/code-archaeology-analysis.md` | Full 8-section completion report |
| `ai-dlc/rules/codebase-rules.md` | Directive rules for AI assistants |
| `ai-dlc/guidelines/forbidden-zones.md` | Areas requiring human pilot intervention |
| `ai-dlc/guidelines/entry-points.md` | Areas safe for autonomous AI work |
| `ai-dlc/rules/code-standards.md` | Extracted code standards with examples |

## Prerequisites

- Must be run inside a git repository
- **GitHub:** `gh` CLI installed and authenticated (`gh auth login`)
- **Azure DevOps:** `AZURE-DEVOPS-TOKEN` environment variable set
- **Plain text / unknown platform:** nothing — report written to disk only

---

Starting code archaeology analysis now...
