# Code Archaeology Analyst

Autonomous codebase archaeology plugin. Triggered by a GitHub Issue or Azure DevOps Work Item tagged `code-archaeology`. Segments the codebase, maps architecture in business language, extracts coding conventions, actively audits for defects and structural problems, classifies all work into typed and prioritized items, and delivers the complete report as ordered comments on the originating issue.

Implements the Phase M1 autonomous execution protocol for AI-DLC onboarding.

---

## Quick Start

1. **Create a GitHub Issue** with the `code-archaeology` label. The body may contain an optional configuration block:

   ```
   ARCHAEOLOGY AGENT — START

   Repository: src/
   Focus areas: src/auth, src/payments
   Skip areas:  src/legacy
   Max segments: 5
   ```

   All fields are optional — the agent uses autonomous defaults if omitted.

2. **Run the command:**

   ```bash
   /code-archaeology issue 42
   /code-archaeology wi 1023
   ```

3. The agent posts "Analysis in Progress" immediately, runs all five phases, then posts five ordered comments with the complete report.

---

## Pipeline

```
/code-archaeology issue 42
    └── orchestrator
          │
          ├── Step 0: Detect platform (GitHub / Azure DevOps / Generic)
          ├── Step 1: Fetch issue #42 — parse configuration block
          ├── Step 2: Post "Analysis in Progress"  ← immediate
          ├── Step 3: Initial codebase survey
          │
          ├── Phase 1:
          │     └── segmentation-analyst  — autonomous segmentation (15–25 files/segment)
          │
          ├── Phases 2–4 (parallel across all segments):
          │     ├── architecture-mapper   — Module/Purpose/Owns/Calls/Exposes + boundaries + flows
          │     ├── pattern-extractor     — 8 patterns: Consistent / Inconsistent / Split
          │     └── due-diligence-auditor — 6 categories: Critical → Low with recommendations
          │
          ├── Phase 5:
          │     └── debt-classifier       — Enhancement / Remediation / Migration at P1–P5
          │
          ├── report-writer  →  ai-dlc/reports/code-archaeology-analysis.md
          │
          └── Post 5 comments + apply 'archaeology-complete' label
```

---

## Agents

| Agent | Phase | Role |
|---|---|---|
| `orchestrator` | All | Platform detection, issue fetch, comment posting, phase coordination |
| `segmentation-analyst` | 1 | Divides codebase into 15–25 file segments; assigns High/Medium/Low confidence per segment |
| `architecture-mapper` | 2 (per segment) | Module/Purpose/Owns/Calls/Exposes descriptions; service boundary rules; data flows |
| `pattern-extractor` | 3 (per segment) | Eight pattern types with Consistent / Inconsistent / Split verdicts |
| `due-diligence-auditor` | 4 (per segment) | Logic defects, design violations, security gaps, fragile patterns, test blind spots, consistency breaks |
| `debt-classifier` | 5 (cross-segment) | Enhancement / Remediation / Migration at P1–P5 priority |
| `report-writer` | Final | Compiles the full structured report to `ai-dlc/reports/code-archaeology-analysis.md` |

---

## Report Structure

```markdown
# Codebase Archaeology Report
├── Segment Map
├── Architecture Summary
│   ├── Capability Map
│   ├── Module Descriptions (Module/Purpose/Owns/Calls/Exposes)
│   ├── Service Boundaries
│   ├── Integration Points
│   ├── Data Flows
│   └── Cross-Segment Dependencies
├── Coding Conventions
│   ├── Consolidated pattern table (8 types — Confirmed / Inconsistency / Split)
│   └── Conventions requiring human decision (Split patterns)
├── Due Diligence Findings
│   ├── Critical
│   ├── High
│   ├── Medium
│   ├── Low
│   └── Findings requiring human decision
├── Work Backlog (P1–P5)
├── Recommended Next Steps
│   ├── Before new development
│   ├── Coding standards to write
│   ├── Items requiring human decision
│   └── Blast radius controls
├── Confidence Assessment
├── Areas Not Analyzed
└── Autonomous Decision Log
```

---

## Comment Thread

| # | Comment | Source |
|---|---------|--------|
| 0 | Analysis in Progress (immediate) | Orchestrator |
| 1 | 🗺️ Architecture & Segment Map | architecture-mapper |
| 2 | 🔍 Coding Conventions | pattern-extractor |
| 3 | 🔎 Due Diligence Findings | due-diligence-auditor |
| 4 | 📋 Work Backlog | debt-classifier |
| 5 | ✅ Analysis Complete + Next Steps | Orchestrator |

---

## Individual Skills

| Skill | Usage |
|---|---|
| `/run-archaeology issue <n>` | Full pipeline |
| `/segment-codebase <path>` | Phase 1 only |
| `/map-architecture <path>` | Phase 2 on one segment |
| `/extract-patterns <path>` | Phase 3 on one segment |
| `/audit-codebase <path>` | Phase 4 on one segment |
| `/classify-debt` | Phase 5 from session findings |
| `/post-report issue <n>` | Post existing report to an issue |

---

## Platform Support

| Remote URL | Platform | Delivery |
|---|---|---|
| `github.com` | GitHub | 5 ordered comments + `archaeology-complete` label |
| `dev.azure.com` / `visualstudio.com` | Azure DevOps | 5 ordered comments + `archaeology-complete` tag |
| Anything else | Generic | Report to disk only |

---

## Key Design Decisions

- **Autonomous execution** — no interactive back-and-forth; the agent makes all segmentation, severity, and classification decisions using judgment rules documented in each agent
- **Issue-triggered** — follows the `req-analyst` pattern: create an issue with a tag, run the command, get results back as comments on the same issue
- **Per-segment parallelism** — Phases 2, 3, and 4 run simultaneously across all segments to minimize elapsed time
- **Single complete report** — all phases run to completion before any comment is posted; no progressive streaming
- **Split pattern handling** — patterns where no single convention dominates are flagged explicitly for human decision, never silently resolved
- **Autonomous Decision Log** — every non-obvious judgment call is recorded, making the agent's reasoning auditable without a human present during execution
- **Agent limitations** — the report includes a permanent "What the Agent Cannot Do" section: Split conventions, business logic correctness, test quality beyond structure, runtime behavior, and in-depth security assessment all require human review

---

## Prerequisites

- Must be run inside a git repository
- **GitHub:** `gh` CLI installed and authenticated (`gh auth login`)
- **Azure DevOps:** `AZURE-DEVOPS-TOKEN` environment variable set
- **Generic:** nothing required
