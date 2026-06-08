---
name: map-architecture
description: Run only Phase 2 — architecture mapping for a single segment. Reads every source file in the segment and produces module descriptions (Module/Purpose/Owns/Calls/Exposes), service boundary rules, integration points, and data flow traces. Usage: /map-architecture <segment-path>
argument-hint: <segment-path>
disable-model-invocation: true
---

Run Phase 2 architecture mapping on the segment at `$ARGUMENTS`.

## Steps

1. Treat the argument as `SEGMENT_SCOPE`. Use the directory name as `SEGMENT_NAME`.

2. Use the **architecture-mapper** agent, passing it:
   - `SEGMENT_NAME` (derived from path)
   - `SEGMENT_SCOPE` (from argument)
   - `TARGET_PATH` (repository root — current directory)

3. Output the architecture map directly. Do not post to any platform.
