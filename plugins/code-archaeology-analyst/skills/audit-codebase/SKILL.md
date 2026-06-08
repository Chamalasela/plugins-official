---
name: audit-codebase
description: Run only Phase 4 — due diligence audit for a single segment. Actively searches for logic defects, design violations, security gaps, fragile patterns, test blind spots, and consistency breaks. Assigns Critical / High / Medium / Low severity with Fix-in-place / Quarantine / Encode-as-prohibition recommendations. Usage: /audit-codebase <segment-path>
argument-hint: <segment-path>
disable-model-invocation: true
---

Run Phase 4 due diligence audit on the segment at `$ARGUMENTS`.

## Steps

1. Treat the argument as `SEGMENT_SCOPE`. Use the directory name as `SEGMENT_NAME`.

2. Use the **due-diligence-auditor** agent, passing it:
   - `SEGMENT_NAME` (derived from path)
   - `SEGMENT_SCOPE` (from argument)
   - `TARGET_PATH` (repository root — current directory)

3. Output the findings directly. Do not post to any platform.

This skill is useful for targeted auditing of a specific module before beginning AI-assisted development on it.
