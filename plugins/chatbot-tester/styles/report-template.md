# Output Style: Chatbot Test Report

This style guide defines the exact format of the test report posted by the `orchestrator` agent.

---

## Audience

Reports are read by **developers, QA engineers, and product owners**. Write in plain language — describe what was tested and what the chatbot said, not which Playwright API was called.

---

## Report Structure

```markdown
🤖 chatbot-tester — Test Report
URL tested: {TEST_URL}
Overall: {PASSED | PARTIAL | FAILED}

| Category                | Result                          |
|-------------------------|---------------------------------|
| UI Availability         | ✅ PASSED                       |
| Functional Accuracy     | ⚠️ PARTIAL (3/4 passed)         |
| Fallback Handling       | ✅ PASSED                       |
| Response Latency        | ✅ PASSED (avg 1.2s)            |
| Conversation Continuity | ✅ PASSED                       |
| Empty Input Handling    | ✅ PASSED                       |
```

After the summary table, append one section per category that has detail to show. Categories that fully PASSED with no Q&A pairs or notable probes may be omitted. Categories with `NOT RUN` status are never expanded.

**Login-blocked report example** (when login fails, all 6 categories are NOT RUN):

```markdown
🤖 chatbot-tester — Test Report
URL tested: {TEST_URL}
Overall: 🔴 BLOCKED — Login failed

| Category                | Result      |
|-------------------------|-------------|
| UI Availability         | ⬜ NOT RUN  |
| Functional Accuracy     | ⬜ NOT RUN  |
| Fallback Handling       | ⬜ NOT RUN  |
| Response Latency        | ⬜ NOT RUN  |
| Conversation Continuity | ⬜ NOT RUN  |
| Empty Input Handling    | ⬜ NOT RUN  |
```

---

## Lite Mode Callout

Include this section immediately after the summary table when `LITE_MODE=true`:

```markdown
---

> ℹ️ **Partial test only** — Functional Accuracy was skipped because no test case was provided.
> To run a full test, create a GitHub issue or Azure DevOps work item with a `chatbot-test` block and re-run:
> ```
> /test-chatbot https://github.com/owner/repo/issues/<n>
> /test-chatbot https://dev.azure.com/org/project/_workitems/edit/<id>
> ```
```

---

## Functional Accuracy Section

Always include this section regardless of verdict. Show every Q&A pair as a collapsible block.

```markdown
---

### Functional Accuracy

<details>
<summary>✅ PASSED — "What are your opening hours?"</summary>

**Question sent:** What are your opening hours?
**Must contain:** 9am, 5pm, Monday
**Bot response:**
> We are open Monday to Friday, 9am until 5pm.

**Verdict:** PASS
**Judge reasoning:** Response contains all required terms in the correct context.
**Response time:** 1.4s
</details>

<details>
<summary>⚠️ PARTIAL — "How do I reset my password?"</summary>

**Question sent:** How do I reset my password?
**Must contain:** email, reset link
**Bot response:**
> You can reset your password via email.

**Verdict:** PARTIAL — response mentions email but omits reset link detail.
**Judge reasoning:** Response partially addresses the question but is missing required terms.
**Response time:** 2.1s
</details>

<details>
<summary>❌ FAILED — "What is your refund policy?"</summary>

**Question sent:** What is your refund policy?
**Must contain:** 30 days, receipt
**Bot response:**
> Please contact our support team for help with refunds.

**Verdict:** FAIL
**Judge reasoning:** Response deflects to support without mentioning 30 days or receipt.
**Response time:** 1.8s
</details>
```

---

## Fallback Handling Section

Include if any probe failed or for visibility.

```markdown
---

### Fallback Handling

<details>
<summary>✅ PASSED — Gibberish input</summary>

**Input sent:** asdfghjkl zxcvbnm qwerty
**Bot response:**
> I'm sorry, I didn't quite understand that. Could you rephrase your question?

**Verdict:** PASS — graceful fallback, non-empty response, no crash.
</details>

<details>
<summary>✅ PASSED — Out-of-scope question</summary>

**Input sent:** What is the capital of Mars?
**Bot response:**
> I can only help with questions related to our products and services. Is there something I can assist you with?

**Verdict:** PASS — graceful out-of-scope handling.
</details>
```

---

## Other Categories

For Conversation Continuity and Empty Input Handling, include a brief block only if the verdict is not PASSED:

```markdown
---

### Conversation Continuity

**Probe sent:** Can you tell me more about that?
**Bot response:**
> I'm not sure what you're referring to. Could you clarify?

**Verdict:** PARTIAL — bot did not retain context from the previous exchange.
```

---

## Verdict Icons

| Verdict | Icon |
|---|---|
| PASSED | ✅ |
| PARTIAL | ⚠️ |
| FAILED | ❌ |
| BLOCKED | 🔴 |
| NOT RUN | ⬜ |

---

## Safety Rules (always enforced)

1. Never include authentication tokens, passwords, API keys, or secrets in any comment
2. Redact credential values as `[REDACTED]` if they appear anywhere in test data
3. The report is always a single comment — never split across multiple comments

---

## Report Boundaries (strictly enforced)

**The report is strictly bounded to the sections defined above.** Never add:

- Suggested fixes or workarounds
- Recommendations or advice
- Root cause analysis
- Next steps or action items
- Code snippets or diffs
- Explanatory commentary beyond the verdict and judge reasoning

The report is a test execution record, not a debugging guide.
