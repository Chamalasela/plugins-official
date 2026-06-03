# Output Style: Code Archaeology Analysis

This style guide defines the conventions used when generating the code archaeology completion report and AI-DLC overlay files. It applies to the `report-writer` and `overlay-writer` agents.

---

## Audience

The primary readers are:
- **AI assistants** working with the codebase — need directive rules they can follow precisely
- **Onboarding engineers** — need business-language descriptions and clear conventions
- **Technical leads** — need the work classification and prioritization to be actionable

---

## Tone and Language

- **Module descriptions:** Always business language. Describe what the user or business gets, not what the code does internally. "Authenticates users via email and password" not "Validates JwtService.verify() return value".
- **Conventions and rules:** Always directive. "Always use X", "Never do Y", "When Z, follow this pattern". No passive voice.
- **Work items:** Plain language. "Add email notification when a user completes onboarding" not "Implement `EmailService.sendOnboardingComplete()` method".
- **Warnings:** Prominent. REQUIRED MANUAL CHECK notices must be in blockquotes and cannot be buried in lists.

---

## Bolt Classification Language

Use precise language to distinguish bolt types:

| Type | Trigger words | Example |
|---|---|---|
| Enhancement | "Add", "Extend", "Support", "Introduce", "Enable" | "Add OAuth 2.0 login via Google" |
| Remediation | "Fix", "Remove", "Add tests for", "Standardize", "Secure", "Resolve" | "Fix missing error handling in payment module" |
| Migration | "Migrate", "Replace", "Upgrade", "Refactor", "Move", "Convert" | "Migrate from Mongoose callbacks to async/await" |

---

## Risk Language

| Level | CSS / Badge | When to apply |
|---|---|---|
| 🔴 High | Critical | Auth, security, data loss, public API breaking changes, financial logic |
| 🟡 Medium | Medium | Core business logic, cross-module integrations, data transformations |
| 🟢 Low | Low | Utilities, configuration, tests, documentation, isolated new features |

---

## Complexity Language

| Level | Definition | Examples |
|---|---|---|
| Low | < 1 day of focused work | Fix a TODO, add a test, update a config value |
| Medium | 1–3 days | Add a new API endpoint, refactor a service method, add integration test suite |
| High | > 3 days | Full module refactor, library migration, multi-service integration |

---

## Overlay File Language

### forbidden-zones.md
- Lead with the zone name as an H2 header
- State the restriction level clearly: "Full stop" (no AI code generation) or "Review required" (AI may draft, human must approve)
- Restriction descriptions must be specific operations, not just areas: "Never modify the JWT signature verification logic" not "Don't touch auth"
- Always include what IS allowed — reading, analyzing, and adding tests are usually safe even in forbidden zones

### entry-points.md
- Lead with the entry point name as an H2 header
- "Safe for" list must be concrete operations, not vague permissions
- Always include "Not safe for (even here)" to prevent scope creep
- Prerequisites must be testable conditions: "All existing tests pass" not "tests are OK"

### codebase-rules.md
- Every rule must start with "Always" or "Never" — no ambiguity
- Every rule must be followed immediately by an example
- Group rules by domain: Naming, Error Handling, ORM, API, Auth, Tests

### code-standards.md
- Lead each standard with "Rule:" on its own line
- Follow immediately with "Example:" and a code block
- Where an anti-pattern is common, include "Anti-example:" as well

---

## Completeness Requirements

The `report-writer` must ensure:
1. Every module has a description — no module appears only in the table without a description section
2. Every Bolt has an evidence citation
3. Every REQUIRED MANUAL CHECK appears in the Executive Summary **and** in Section 6
4. Section 8 (Recommended Next Steps) always contains at least one actionable item
5. The Suggested AI-DLC Work Order must be a numbered list — never unordered

---

## Report Filename

The report is always written to:

```
ai-dlc/code-archaeology-analysis.md
```

The overlay files are always written to:

```
ai-dlc/rules/codebase-rules.md
ai-dlc/guidelines/forbidden-zones.md
ai-dlc/guidelines/entry-points.md
ai-dlc/rules/code-standards.md
```

---

## General Rules

1. Never invent capabilities or patterns — only document what is found in the codebase
2. Never hide inconsistencies — flag them explicitly in the Inconsistencies table
3. Never classify a module as an entry point if it has no tests — always require tests first
4. Every work item must be traceable to an observation in the Phase 1 analysis
5. REQUIRED MANUAL CHECKs are non-negotiable — they cannot be resolved by the agent
