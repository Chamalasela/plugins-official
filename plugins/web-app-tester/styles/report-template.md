# Output Style: Web App Test Execution Report

This style guide defines the exact format of the test execution report posted as a GitHub comment by the `orchestrator` agent.

---

## Audience

Reports are read by **developers, QA engineers, and product owners** reviewing a PR or issue. Write step descriptions in plain language — describe what was tested, not which Playwright API was called.

---

## Report Structure

The report is posted as a single comment. It has five mandatory sections — **Header**, **Test Plan Summary**, **Step Results table**, **Overall Result**, and **Footer** — followed by an optional **Detailed Step Log** (FAILED / BLOCKED steps only) and an optional **Notes** block.

### 1. Header

```markdown
## Web App Test Execution Report
**Verdict:** {PASSED | FAILED | BLOCKED}
**{PR | Issue | Work Item}:** #{ENTRY_ID} {ENTRY_TITLE}
**Test URL:** {TEST_URL}{IF LOCAL_STACK} (local stack — {LOCAL_STACK_NOTE}){END IF}
**Environment:** IS_PRODUCTION={true | false} ({read-only mode — write steps skipped | all steps executed})
**Timestamp:** {ISO 8601 UTC timestamp of run start}
**Duration:** {total run duration, e.g. 3.2s}
**Browser:** Chromium headless
```

`LOCAL_STACK_NOTE` is free-form (e.g. `Vercel preview protected by SSO`) — include it only when the test URL is a localhost address or the tester switched from a remote preview to a local stack.

### 2. Test Plan Summary

A short paragraph (2–4 sentences) describing:

- What the PR / issue / work item introduces or changes
- What the test plan covers (the major areas exercised)

Derive this from the PR title, description, and the generated or provided test plan. Write in past tense from the perspective of the test run ("This PR introduces … The test plan covers …").

```markdown
## Test Plan Summary
{narrative paragraph}
```

### 3. Step Results table

One row per step. The `Actual` column is what the post-step snapshot showed; `Expected` is the intended outcome. Both must be written in business language — one concise phrase each.

```markdown
## Step Results

| # | Description | Status | Actual | Expected | Duration |
|---|-------------|--------|--------|----------|----------|
| 1 | {step description} | ✅ PASSED | {observed} | {expected} | {duration, e.g. 671ms} |
| 2 | {step description} | ❌ FAILED | {observed} | {expected} | {duration} |
| 3 | {step description} | 🔴 BLOCKED | {observed} | {expected} | — |
```

- `Duration` is the wall-clock time the step took. Show `—` for BLOCKED steps where execution could not start.
- Do not truncate `Actual` or `Expected` — one sentence each is fine; use plain language.

### 4. Overall Result

A brief narrative section (3–8 bullet points) summarising the outcome. For PASSED runs, list the major behaviours verified. For FAILED / BLOCKED runs, state what broke and (for BLOCKED) what prevented execution — no suggested fixes.

```markdown
## Overall Result
{X} / {TOTAL} steps {PASSED} — {Y} FAILED — {Z} BLOCKED

{For PASSED:}
All functionality introduced in this PR is working correctly:
- {behaviour verified 1}
- {behaviour verified 2}
…

{For FAILED or BLOCKED:}
The run {failed | was blocked} on {N} step(s):
- {short description of what did not pass and why — factual only}
…
```

### 5. Detailed Step Log (conditional — FAILED and BLOCKED steps only)

Emit this section only when the run contains at least one FAILED or BLOCKED step. For each such step, in order:

```markdown
## Detailed Step Log

### Step {N} — {step description}
- **Action:** {plain-language description of what was attempted}
- **Target:** {role + accessible name of the element, or the URL for navigate; omit if not applicable}
- **Input:** {value entered, or `[REDACTED]` for secrets; omit if no input}
- **Expected:** {one sentence — the outcome the step was supposed to produce}
- **Observed:** {one sentence — what the post-action snapshot actually showed}
- **Status:** ❌ FAILED | 🔴 BLOCKED
- **Attempts:** {1..3}
- **Screenshot:** {`_wat_screenshot_{N}.png` captured at point of failure | not applicable}
- **Reason:** {short cause — factual only}
```

**Field rules:**

- `Target`, `Input`, `Screenshot`, and `Reason` are **conditional** — omit them when not applicable.
- `Action`, `Expected`, `Observed`, `Status`, `Attempts`, and `Reason` are **always** present for FAILED / BLOCKED steps.
- Plain business language only. Do not describe Playwright commands, `eN` refs, CSS selectors, or YAML snapshots.

For BLOCKED steps where retry attempts produced useful output, include a brief retry summary:

```markdown
**Retry log:** attempt 1 — {what happened}; attempt 2 — {what happened}; attempt 3 — {final outcome}
```

### 6. Notes (optional)

Include a `## Notes` block only when there is a **meaningful operational caveat** that is not already captured in the step results — for example, a Vercel preview protected by SSO that forced a local-stack fallback, or a known flaky external dependency. Do not add notes that merely restate step outcomes.

### 7. Footer

Always end the report with:

```markdown
---
*Generated by Web App Tester — Python/Playwright (headless Chromium) — {MODEL_ID}*
```

`MODEL_ID` is the Claude model that produced the report (e.g. `claude-sonnet-4-6`).

---

## Overall Result Logic

| Condition | Overall Result |
|---|---|
| All steps passed | **PASSED** |
| One or more steps failed (all steps were attempted) | **FAILED** |
| One or more steps could not execute (element not found, page error, timeout) | **BLOCKED** |

A run with both FAILED and BLOCKED steps uses **BLOCKED** as the overall result.

---

## Step Description Format

Write step descriptions in business language — describe the **user action and observed outcome**, not the technical mechanism.

| ❌ Avoid | ✅ Prefer |
| --- | --- |
| `mcp__playwright__browser_click called on #submit-btn` | `Click the Submit button on the registration form` |
| `browser_fill input[name=email]` | `Fill in the email address field with a valid address` |
| `assert .toast-message contains text` | `Verify success toast appears after form submission` |

---

## Step Status Rules

| Status | When to use |
| --- | --- |
| ✅ PASSED | Action completed AND expected outcome was observed |
| ❌ FAILED | Action completed BUT expected outcome was NOT observed (wrong text, element absent, wrong page) |
| 🔴 BLOCKED | Action could not be executed after 3 retries (element not found, navigation error, timeout, crash) |

A step that was **skipped due to production environment read-only mode** is marked `🔴 BLOCKED` with reason: `Skipped — production environment, read-only mode`.

---

## Production Notice

If `IS_PRODUCTION=true`, the Environment line in the header must read:

```
IS_PRODUCTION=true (read-only mode — write steps skipped)
```

Steps that were skipped due to this restriction are listed in the table as `🔴 BLOCKED` with reason `Skipped — production environment, read-only mode`.

---

## Safety Rules (always enforced)

1. Never include authentication tokens, API keys, passwords, or secrets in any comment
2. Never describe credential values — redact them as `[REDACTED]` if they appear in test data
3. Screenshots are referenced only for FAILED and BLOCKED steps
4. The report comment is always a single comment — never split across multiple comments

---

## Report Boundaries (strictly enforced)

**The report is strictly bounded to the sections defined above.** Nothing else.

✅ **Allowed and required:**
- Factual description of the action attempted (plain language)
- Factual description of the observed outcome from the post-action snapshot
- The expected outcome as stated or implied by the test plan
- Attempts count, screenshot reference, short failure cause, and timing

❌ **Prohibited anywhere in the report:**
- Suggested fixes, workarounds, or "you should try…" statements
- Recommendations, advice, or test-improvement ideas
- Root cause analysis (why the bug exists, where in the code it might live)
- Next steps or action items for the developer
- Code snippets, diffs, stack traces, selectors, or YAML snapshot dumps
- Subjective commentary ("the UI feels slow", "this seems intentional")

The distinction: documenting **what was tried and what happened** is the test execution record and belongs in the report. Reasoning about **why** it happened or **what to do next** is debugging and belongs in a separate human review — not in this comment.
