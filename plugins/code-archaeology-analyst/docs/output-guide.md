# Output Guide: Code Archaeology Analysis

This guide explains the files produced by the code archaeology analysis pipeline and how to use them for AI-DLC work.

---

## Output Files Overview

| File | Purpose | Who reads it |
|---|---|---|
| `ai-dlc/code-archaeology-analysis.md` | Full completion report | Engineers, tech leads, AI assistants |
| `ai-dlc/rules/codebase-rules.md` | How to work with this codebase | AI assistants |
| `ai-dlc/guidelines/forbidden-zones.md` | Where AI must not act alone | AI assistants, human pilots |
| `ai-dlc/guidelines/entry-points.md` | Where AI can act autonomously | AI assistants |
| `ai-dlc/rules/code-standards.md` | Code conventions to follow | AI assistants, new engineers |

---

## `ai-dlc/code-archaeology-analysis.md`

The main completion report. Contains:
- Executive summary (languages, framework, module count, work item summary)
- Module map with business-language descriptions
- Capability map table
- Service boundaries and integration points
- Extracted code patterns and conventions
- Work classification (Enhancement / Remediation / Migration Bolts)
- Test coverage baseline and feature flag status
- Recommended next steps and AI-DLC work order

**Use this to:** Understand the full picture before starting AI-DLC work. Share with tech leads for planning.

---

## `ai-dlc/rules/codebase-rules.md`

A directive rules file for AI assistants. Written as "Always/Never/When" statements derived from the archaeology analysis.

**Use this to:** Import into your CLAUDE.md or AI assistant context to enforce codebase-specific rules.

---

## `ai-dlc/guidelines/forbidden-zones.md`

Areas where AI assistants must NOT produce code without explicit human pilot oversight. Each zone lists:
- What the zone covers
- Why it requires human oversight
- What specific operations are restricted
- What is still allowed (e.g., reading/analysis)

**Use this to:** Prevent AI assistants from making unsafe autonomous changes in critical areas.

---

## `ai-dlc/guidelines/entry-points.md`

Areas where AI assistants can safely proceed without human pilot confirmation. Each entry point lists:
- What operations are safe to perform
- What operations remain restricted even here
- Prerequisites (conditions that must be true before proceeding)

**Use this to:** Identify where to start AI-DLC work for maximum speed and minimum risk.

---

## `ai-dlc/rules/code-standards.md`

Machine-readable code standards extracted from the codebase patterns. Covers:
- Naming conventions (files, variables, functions, classes)
- File structure rules
- Error handling rules
- API shape rules
- Test rules
- Linting/formatting rules

**Use this to:** Ensure AI-generated code matches the existing codebase conventions exactly.

---

## Work Classification: Bolt Types

| Type | Meaning | Example |
|---|---|---|
| **Enhancement** | New functionality or improvements | Add a new API endpoint, extend an existing service |
| **Remediation** | Fix issues, improve quality, reduce debt | Fix a bug, add missing tests, resolve a security issue |
| **Migration** | Move or transform existing functionality | Upgrade a library, refactor module structure |

Each Bolt is classified with:
- **Complexity:** Low (< 1 day) / Medium (1–3 days) / High (> 3 days)
- **Risk:** 🔴 High / 🟡 Medium / 🟢 Low
- **Evidence:** What in the codebase signaled this work item

---

## Integrating into CLAUDE.md

After the analysis completes, integrate the overlay files into your project's CLAUDE.md:

```markdown
# Codebase Rules
See ai-dlc/rules/codebase-rules.md for AI assistant rules.

# Code Standards
See ai-dlc/rules/code-standards.md for code standards.

# Forbidden Zones
See ai-dlc/guidelines/forbidden-zones.md for areas requiring human oversight.

# Entry Points
See ai-dlc/guidelines/entry-points.md for safe autonomous work areas.
```
