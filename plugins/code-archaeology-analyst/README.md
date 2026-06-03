# Code Archaeology Analyst

Deep codebase archaeology analysis plugin. Triggered by a GitHub Issue or Azure DevOps Work Item tagged `code-archaeology`. Fetches the issue, scans the codebase module by module, classifies all identified work, writes AI-DLC overlay files, and posts the full analysis back as ordered comments on the originating issue.

Implements the Phase M1 setup guide workflow for AI-DLC onboarding.

---

## Quick Start

1. **Create a GitHub Issue** (or Azure DevOps Work Item) with the `code-archaeology` label:

   ```markdown
   Title: Run code archaeology analysis

   **Target path:** src/          (optional — defaults to repo root)
   **Modules of interest:** src/auth, src/payments   (optional)

   Please run a full code archaeology analysis to prepare for AI-DLC work.
   ```

2. **Run the command:**

   ```bash
   /code-archaeology issue 42
   /code-archaeology wi 1023
   ```

3. The agent posts an "Analysis in Progress" comment immediately, then posts 5 ordered comments as the analysis completes.

---

## Pipeline

```
/code-archaeology issue 42
    └── orchestrator
          │
          ├── Step 0: Detect platform (GitHub / Azure DevOps / Generic)
          ├── Step 1: Fetch issue #42 — parse target path and context
          ├── Step 2: Post "Analysis in Progress" comment  ← immediate
          ├── Step 3: Initial codebase survey
          │
          ├── Phase 1 (parallel):
          │     ├── module-scanner     — reads every module, writes business descriptions,
          │     │                        produces capability map, identifies service boundaries
          │     └── pattern-extractor  — extracts naming conventions, error handling,
          │                             ORM usage, API shapes, auth patterns, test patterns,
          │                             data flows, and inconsistencies
          │
          ├── Phase 2:
          │     └── work-classifier    — Enhancement / Remediation / Migration Bolts
          │
          ├── Post comments 1–3: Module Map | Patterns | Work Classification
          │
          ├── Phase 3 (parallel):
          │     ├── overlay-writer     — writes ai-dlc/ rule and guideline files
          │     └── coverage-analyst   — test coverage + feature flag check
          │
          ├── Phase 4:
          │     └── report-writer  →  ai-dlc/code-archaeology-analysis.md
          │
          └── Post comments 4–5: Blast Radius Controls | Analysis Complete
                + Apply 'archaeology-complete' label/tag
```

---

## Comment Thread

| # | Comment | Source |
|---|---------|--------|
| 0 | Analysis in Progress (immediate) | Orchestrator |
| 1 | 🗺️ Module Map & Capability Map | module-scanner |
| 2 | 🔍 Code Patterns & Conventions | pattern-extractor |
| 3 | 📋 Work Classification | work-classifier |
| 4 | 🛡️ Blast Radius Controls | coverage-analyst |
| 5 | ✅ Analysis Complete + Next Steps | Orchestrator |

Comments with no meaningful findings are skipped.

---

## Agents

| Agent | Phase | Role |
|---|---|---|
| `orchestrator` | All | Platform detection, issue fetch, comment posting, phase coordination |
| `module-scanner` | 1 (parallel) | Enumerates every module; writes business descriptions; produces capability map |
| `pattern-extractor` | 1 (parallel) | Reads 10–20 representative files; extracts all conventions and patterns; maps data flows |
| `work-classifier` | 2 | Classifies all identified work into Enhancement / Remediation / Migration Bolts |
| `overlay-writer` | 3 (parallel) | Writes four AI-DLC overlay files under `ai-dlc/` |
| `coverage-analyst` | 3 (parallel) | Runs test suite for first entry-point module; assesses feature flag implementation |
| `report-writer` | 4 | Produces the 8-section completion report at `ai-dlc/code-archaeology-analysis.md` |

---

## Platform Support

| Remote URL | Platform | Delivery |
|---|---|---|
| `github.com` | GitHub | Ordered comments via `gh` CLI + `archaeology-complete` label |
| `dev.azure.com` / `visualstudio.com` | Azure DevOps | Ordered comments via REST API + `archaeology-complete` tag |
| Anything else | Generic | Report written to `ai-dlc/code-archaeology-analysis.md` only |

---

## Output Files (always written to disk)

| File | Description |
|---|---|
| `ai-dlc/code-archaeology-analysis.md` | Full 8-section completion report |
| `ai-dlc/rules/codebase-rules.md` | Directive rules for AI assistants — Always/Never/When |
| `ai-dlc/guidelines/forbidden-zones.md` | Areas requiring human pilot intervention |
| `ai-dlc/guidelines/entry-points.md` | Areas safe for autonomous AI work |
| `ai-dlc/rules/code-standards.md` | Extracted code standards with examples |

---

## Work Classification: Bolt Types

| Bolt | Meaning | Example |
|---|---|---|
| **Enhancement** | New functionality the codebase is ready to receive | Add OAuth login, add a new API endpoint |
| **Remediation** | Fix issues, improve quality, reduce debt | Fix a bug, add missing tests, resolve a security issue |
| **Migration** | Move or transform existing functionality | Migrate to a new library, refactor module structure |

---

## Flags

| Flag | Effect |
|---|---|
| `--no-overlay` | Skip writing `ai-dlc/` overlay files |
| `--no-coverage` | Skip test coverage analysis and feature flag check |

---

## Key Design Decisions

- **Issue-triggered** — follows the `req-analyst` pattern: create an issue with a tag, run the command, get results back as comments on the same issue
- **Immediate "in progress" comment** — posted before any analysis begins so the team knows work has started
- **Autonomous execution** — no confirmation gate; work classification is posted as a comment for the team to review and respond to
- **Non-destructive** — the original issue description is never modified; all output is posted as separate comments
- **Dual output** — results posted as comments on the issue AND written to disk as AI-DLC overlay files
- **Platform-agnostic agents** — sub-agents are source-agnostic; only Steps 0–2 and 9 are platform-specific
- **Budget warnings** — agents emit explicit `⚠️ Tool budget reached` warnings if they can't fully analyze the codebase
- **REQUIRED MANUAL CHECK** — if tests can't run, coverage-analyst flags this prominently

---

## Prerequisites

- Must be run inside a git repository with an issue/work item to reference
- **GitHub:** `gh` CLI installed and authenticated (`gh auth login`)
- **Azure DevOps:** `AZURE-DEVOPS-TOKEN` environment variable set
- **Generic / plain text:** nothing — report written to disk only
