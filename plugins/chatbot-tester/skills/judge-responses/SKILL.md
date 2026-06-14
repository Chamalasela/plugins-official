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

## Step 1: Judge Q&A Pairs and Conversation Continuity (Single Batched LLM Call)

Extract all Q&A pairs from `CATEGORY_RESULTS.functional_accuracy.qa_pairs` and the continuity probe result from `CATEGORY_RESULTS.conversation_continuity.probe_results[0]`.

Before judging, check each Q&A pair's `actual_response`. If it equals `(response capture failed — no matching bot message element found)`, assign `verdict: "FAIL"` and `reasoning: "Response capture failed — no bot message element matched; cannot evaluate."` directly without including it in the LLM call.

For all remaining pairs, truncate `actual_response` to 500 tokens before including it in the judge prompt.

Make **one single LLM call** with all Q&A pairs and the continuity probe batched together. Use this prompt structure:

```
You are a strict but fair QA judge evaluating an AI chatbot's responses.

## Q&A Pairs
For each Q&A pair below, return a verdict of PASS, PARTIAL, or FAIL and a one-line reason.

Verdict criteria:
- PASS: the response clearly and correctly addresses the question and contains all required terms in a meaningful context
- PARTIAL: the response is relevant and partially correct but missing one or more required terms or key details
- FAIL: the response is incorrect, irrelevant, deflects without answering, or contains none of the required terms

{for each pair}
---
Index: {n}
Question: {question}
Required terms (must appear in a meaningful context): {must_contain joined by ", "}
Bot response (truncated to 500 tokens): {actual_response_truncated}
---

## Conversation Continuity Probe
The follow-up question below was sent after the Q&A exchange above. Judge whether the bot's response demonstrates it retained context from the prior conversation.

Follow-up sent: {continuity_probe}
Bot response: {continuity_response_truncated}

Verdict criteria for continuity:
- PASS: response is topically relevant to the follow-up and shows the bot remembered prior context
- PARTIAL: response is non-empty and on-topic but generic — could have been given without any prior context
- FAIL: response is empty, asks the user to clarify what they mean, or shows no awareness of prior context

Return a JSON object:
{
  "qa_pairs": [
    { "index": n, "verdict": "PASS|PARTIAL|FAIL", "reasoning": "one-line explanation" },
    ...
  ],
  "continuity": { "verdict": "PASS|PARTIAL|FAIL", "reasoning": "one-line explanation" }
}
```

Parse the JSON response and attach `verdict` and `judge_reasoning` to each Q&A pair and the continuity probe in `JUDGED_RESULTS`.

**If no Q&A pairs exist** (lite mode), omit the Q&A Pairs section and judge continuity only.

---

## Step 2: Judge Probe Responses (Deterministic)

For Fallback and Empty Input probes, apply deterministic rules (no LLM call needed). Conversation Continuity is already judged in Step 1.

### Fallback probes (gibberish / out-of-scope)

- **PASSED** if: response is non-empty AND does not contain raw exception text, stack traces, HTTP error codes (500, 404), or empty string
- **FAILED** if: response is empty, contains a stack trace, or contains an unhandled error message
- **BLOCKED** if: no response was captured (timeout or crash)

### Empty Input probe

- **PASSED** if: no crash occurred AND the input field is still interactable after submission
- **FAILED** if: the page crashed, threw a visible error, or the input field became non-interactable

---

## Step 3: Compute Category Verdicts

For each category, compute the category verdict using the Category Verdicts table in `docs/verdict-logic.md`.

---

## Completion

Hand off to `skills/post-test-report/SKILL.md` with `JUDGED_RESULTS`, `TEST_URL`, `ENTRY_TYPE`, `ENTRY_ID`, `PLATFORM`, `LITE_MODE` in scope.
