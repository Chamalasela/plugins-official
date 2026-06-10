# Output Style: Web App Test Execution Report

This style guide defines the exact format of the test execution report posted as a GitHub comment by the `orchestrator` agent.

---

## Audience

Reports are read by **developers, QA engineers, and product owners** reviewing a PR or issue. Write step descriptions in plain language — describe what was tested, not which Playwright API was called.

---

## Report Structure

The report is posted as a single GitHub comment. Use this exact structure:

```markdown
🤖 web-app-tester — Test Execution Report
URL tested: {TEST_URL}
{IF PRODUCTION_WARNING}⚠️ URL appears to be production. Executed read-only steps only.{END IF}
Total: {N} | ✅ Passed: {X} | ❌ Failed: {Y} | 🔴 Blocked: {Z}
Overall: {PASSED | FAILED | BLOCKED}

{one <details> block per step — see Step Detail Block Format below}
```

### Step Detail Block Format

Every step gets a `<details>` block. The collapsed `<summary>` line shows status, description, and duration at a glance. Expanding reveals the action and, for non-passing steps, the failure reason.

**PASSED step:**
```markdown
<details>
<summary>Step {N} — ✅ {step description} ({duration}s)</summary>

**Action:** {action sentence}
**Duration:** {duration}s

</details>
```

**FAILED step:**
```markdown
<details>
<summary>Step {N} — ❌ {step description} ({duration}s)</summary>

**Action:** {action sentence}
**Duration:** {duration}s
**Reason:** {what went wrong}

</details>
```

**BLOCKED step:**
```markdown
<details>
<summary>Step {N} — 🔴 {step description} ({duration}s)</summary>

**Action:** {action sentence}
**Duration:** {duration}s
**Reason:** {what went wrong / Skipped — production URL, read-only mode}

</details>
```

Duration is displayed in seconds rounded to one decimal place (e.g. `1.2s`). For BLOCKED steps with no duration (e.g. skipped due to PRODUCTION_WARNING), omit the duration from the summary and the Duration line.

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
|---|---|
| `mcp__playwright__browser_click called on #submit-btn` | `Click the Submit button on the registration form` |
| `browser_fill input[name=email]` | `Fill in the email address field with a valid address` |
| `assert .toast-message contains text` | `Verify success toast appears after form submission` |

---

## Step Status Rules

| Status | When to use |
|---|---|
| ✅ PASSED | Action completed AND expected outcome was observed |
| ❌ FAILED | Action completed BUT expected outcome was NOT observed (wrong text, element absent, wrong page) |
| 🔴 BLOCKED | Action could not be executed after 3 retries (element not found, navigation error, timeout, crash) |

A step that was **skipped due to production URL read-only mode** is marked `🔴 BLOCKED` with reason: `Skipped — production URL, read-only mode`.

---

## Retry Log (optional)

For BLOCKED steps, if retry attempts produced informative output (e.g. element selector, error message), include a brief retry summary:

```markdown
**Step 3 — Verify order confirmation message**
Reason: Element `.order-confirmation` not found after 3 retries (5s between each)
Attempts: 1 — timeout after 5s; 2 — timeout after 5s; 3 — timeout after 5s
Screenshot: captured at point of failure
```

---

## Production Warning

If the tested URL appears to be a production domain, the report must include this warning immediately after the URL line:

```
⚠️ URL appears to be production. Executed read-only steps only.
```

Steps that were skipped due to this restriction are listed as `🔴 BLOCKED` with reason `Skipped — production URL, read-only mode`.

---

## Safety Rules (always enforced)

1. Never include authentication tokens, API keys, passwords, or secrets in any comment
2. Never describe credential values — redact them as `[REDACTED]` if they appear in test data
3. Screenshots are attached only for FAILED and BLOCKED steps
4. The report comment is always a single comment — never split across multiple comments

---

## Report Boundaries (strictly enforced)

**The report is strictly bounded to the sections defined above.** Never add content outside this structure. Prohibited additions include:

- Suggested fixes or workarounds
- Recommendations or advice
- Root cause analysis
- Next steps or action items
- Code snippets or diffs
- Explanatory commentary or observations

The report is a test execution record, not a debugging guide. Any insight beyond pass/fail/blocked belongs in a separate human review — not in this comment.
