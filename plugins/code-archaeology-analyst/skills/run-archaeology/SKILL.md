---
name: run-archaeology
description: Runs the full code archaeology analysis pipeline. Scans every module, extracts patterns, classifies work into Enhancement/Remediation/Migration Bolts, writes ai-dlc/ overlay files, checks test coverage, and delivers the completion report at ai-dlc/code-archaeology-analysis.md.
triggers:
  - /code-archaeology
---

# Skill: Run Archaeology

Triggers the **orchestrator** agent to run the full code archaeology analysis pipeline for the given path.

## Usage

```
/code-archaeology [path] [--no-overlay] [--no-coverage]
```

## What It Does

1. Surveys the codebase structure, languages, and frameworks
2. Runs `module-scanner` and `pattern-extractor` in parallel (Phase 1)
3. Runs `work-classifier` and presents the classification for engineer confirmation (Phase 2)
4. After confirmation, runs `overlay-writer` and `coverage-analyst` in parallel (Phase 3)
5. Produces the completion report at `ai-dlc/code-archaeology-analysis.md` (Phase 4)

## Output

- `ai-dlc/code-archaeology-analysis.md` — full completion report
- `ai-dlc/rules/codebase-rules.md` — rules for working with this codebase
- `ai-dlc/guidelines/forbidden-zones.md` — forbidden zones
- `ai-dlc/guidelines/entry-points.md` — safe entry points
- `ai-dlc/rules/code-standards.md` — code standards
