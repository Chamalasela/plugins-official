---
name: judge-responses
description: Phase 3 of chatbot-tester. Makes a single batched LLM call to judge all Q&A pairs from the Functional Accuracy category. Also judges fallback, continuity, and empty input probe responses. Outputs JUDGED_RESULTS with verdict and reasoning added to each item.
disable-model-invocation: true
---

# Phase 3 — Judge Responses

This skill is invoked by the **orchestrator** agent. It is not a standalone slash command.

## Inputs

| Variable | Source | Description |
|---|---|---|
| `CATEGORY_RESULTS` | Phase 2 | Structured results per test category including verbatim bot responses |
| `KNOWLEDGE` | orchestrator | Parsed contents of the `chatbot-test` block from the GitHub issue or Azure DevOps work item |

## Outputs

`JUDGED_RESULTS` — same structure as `CATEGORY_RESULTS` with `verdict` and `judge_reasoning` added to each Q&A pair and probe result.

---

## Step 1: Judge Q&A Pairs (Single Batched LLM Call)

Extract all Q&A pairs from `CATEGORY_RESULTS.functional_accuracy.qa_pairs`.

For each pair, truncate `actual_response` to 500 tokens before including it in the judge prompt.

Make **one single LLM call** with all pairs batched. Use this prompt structure:

```
You are a strict but fair QA judge evaluating an AI chatbot's responses.

For each Q&A pair below, return a verdict of PASS, PARTIAL, or FAIL and a one-line reason.

Verdict criteria:
- PASS: the response clearly and correctly addresses the question and contains all required terms in a meaningful context
- PARTIAL: the response is relevant and partially correct but missing one or more required terms or key details
- FAIL: the response is incorrect, irrelevant, deflects without answering, or contains none of the required terms

Q&A Pairs:
{for each pair}
---
Index: {n}
Question: {question}
Required terms (must appear in a meaningful context): {must_contain joined by ", "}
Bot response (truncated to 500 tokens): {actual_response_truncated}
---

Return a JSON array with one object per pair:
[
  { "index": n, "verdict": "PASS|PARTIAL|FAIL", "reasoning": "one-line explanation" },
  ...
]
```

Parse the JSON response and attach `verdict` and `judge_reasoning` to each Q&A pair in `JUDGED_RESULTS`.

---

## Step 2: Judge Probe Responses

For each probe in the Fallback, Conversation Continuity, and Empty Input categories, apply these deterministic rules (no LLM call needed):

### Fallback probes (gibberish / out-of-scope)

- **PASSED** if: response is non-empty AND does not contain raw exception text, stack traces, HTTP error codes (500, 404), or empty string
- **FAILED** if: response is empty, contains a stack trace, or contains an unhandled error message
- **BLOCKED** if: no response was captured (timeout or crash)

### Conversation Continuity probe

- **PASSED** if: response is non-empty AND does not contain phrases like "I don't know what you mean", "I'm not sure what you're referring to", or "Could you start over"
- **PARTIAL** if: response is non-empty but appears to restart the conversation rather than build on it
- **FAILED** if: response is empty or explicitly resets context

### Empty Input probe

- **PASSED** if: no crash occurred AND the input field is still interactable after submission
- **FAILED** if: the page crashed, threw a visible error, or the input field became non-interactable

---

## Step 3: Compute Category Verdicts

For each category, compute the overall category verdict:

| Category | Verdict logic |
|---|---|
| UI Availability | Direct from Phase 2 (structural check — no LLM judgment) |
| Functional Accuracy | PASSED if all pairs PASS; PARTIAL if any PARTIAL and no FAIL; FAILED if any FAIL |
| Fallback Handling | PASSED if all probes pass; FAILED if any probe fails |
| Response Latency | PASSED if all responses ≤ 30s; FAILED if any exceeded timeout |
| Conversation Continuity | Direct from probe verdict |
| Empty Input Handling | Direct from probe verdict |

---

## Completion

Hand off to `skills/post-test-report/SKILL.md` with `JUDGED_RESULTS`, `TEST_URL`, `ENTRY_TYPE`, `ENTRY_ID`, `PLATFORM` in scope.
