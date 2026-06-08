# Output Style: Code Archaeology Analysis

This style guide defines the conventions used when generating the archaeology report. It applies to the `report-writer` agent and to the comment bodies posted by the orchestrator.

---

## Audience

- **Developers reading comments** on the issue — need scannable summaries they can action in minutes
- **AI assistants** consuming the report — need directive rules and unambiguous verdicts
- **Technical leads** reviewing the backlog — need priorities justified by evidence

---

## Language Rules

**Module descriptions** — always business language. Describe what the user or business gets, never what the code does internally.
- "Authenticates users and issues session tokens" not "Validates JwtService.verify() and sets req.user"

**Findings** — specific and locatable. Every finding must include a file path or function name.
- "Missing auth check on `POST /api/v1/users` in `src/api/users.ts:43`" not "some endpoints lack auth"

**Work items** — specific enough to act on without further clarification.
- "Add input validation middleware to all public API routes in `src/api/`" not "improve input validation"

**Verdict language** — use exactly these terms, no variations:
- `Consistent` / `Inconsistent` / `Split` / `Not observed` (pattern verdicts)
- `Confirmed` (cross-segment consolidation of a Consistent pattern)
- `Critical` / `High` / `Medium` / `Low` (finding severity)
- `Fix-in-place` / `Quarantine` / `Encode as prohibition` (recommendations)
- `P1` through `P5` (work item priority)
- `Enhancement` / `Remediation` / `Migration` (work item type)

---

## Comment Structure

Each posted comment must have a clear H2 heading and be scannable in under 60 seconds.

**Skip sections with no findings** — never write "None identified" or "No issues found."

**Decision Log entries** — always include the phase prefix: `Phase 1 —`, `Phase 2 —`, etc.

---

## Severity Justification

Every Critical and High finding must include:
1. The exact file and function where the problem exists
2. What a developer would experience if new code inherits this pattern
3. A concrete recommendation (Fix-in-place / Quarantine / Encode as prohibition)

---

## Split Pattern Handling

A Split pattern means **no rule can be written without a human decision**. Never recommend one variant over the other — state both objectively and specify what decision is needed:

> "Error handling is Split: thrown exceptions (`throw new Error(...)`) in `src/api/`, returned error objects (`{ ok: false, error }`) in `src/services/`. Decision needed: which style to standardize on before AI-assisted development begins."

---

## Report File

Always written to:

```
ai-dlc/reports/code-archaeology-analysis.md
```

Platform comments contain summaries. The file contains the complete report.
