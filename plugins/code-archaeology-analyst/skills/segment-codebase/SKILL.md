---
name: segment-codebase
description: Run only Phase 1 — autonomous segmentation. Reads the codebase structure and divides it into analysis-ready segments without asking. Applies the 15–25 file size limit, cohesion grouping, and confidence self-assessment. Usage: /segment-codebase [path]
argument-hint: [path]
disable-model-invocation: true
---

Run Phase 1 segmentation on the codebase at `$ARGUMENTS` (defaults to `.`).

## Steps

1. Survey the directory structure:

   ```bash
   find "${PATH:-.}" -maxdepth 3 -type d \
     -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*/vendor/*' \
     | sort | head -60
   ```

2. Use the **segmentation-analyst** agent, passing it:
   - `TARGET_PATH` (from argument or `.`)
   - `FOCUS_AREAS`, `SKIP_AREAS`, `MAX_SEGMENTS` (from arguments or defaults)
   - The directory tree from step 1

3. Output the segment plan directly. Do not post to any platform — this is a local-only analysis.

If no argument is given, analyze the current directory.
