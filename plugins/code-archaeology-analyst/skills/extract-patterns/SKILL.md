---
name: extract-patterns
description: Run only Phase 3 — pattern extraction for a single segment. Reads 10–20 representative files and extracts eight pattern types (naming, error handling, ORM/DB, API shape, auth, testing, dependency wiring, configuration) with Consistent / Inconsistent / Split verdicts. Usage: /extract-patterns <segment-path>
argument-hint: <segment-path>
disable-model-invocation: true
---

Run Phase 3 pattern extraction on the segment at `$ARGUMENTS`.

## Steps

1. Treat the argument as `SEGMENT_SCOPE`. Use the directory name as `SEGMENT_NAME`.

2. Use the **pattern-extractor** agent, passing it:
   - `SEGMENT_NAME` (derived from path)
   - `SEGMENT_SCOPE` (from argument)
   - `TARGET_PATH` (repository root — current directory)

3. Output the pattern extraction results directly. Do not post to any platform.
