---
name: run-playwright-session
description: Phase 2 of chatbot-tester. Opens the target URL in headless Chromium, logs in if required, translates plain language widget hints to Playwright selectors, and runs six test categories against the chatbot. Outputs structured category results with verbatim bot responses for all Q&A pairs.
disable-model-invocation: true
---

# Phase 2 — Run Playwright Session

This skill is invoked by the **orchestrator** agent. It is not a standalone slash command.

## Inputs

| Variable | Source | Description |
|---|---|---|
| `TEST_URL` | Phase 1 | The URL to open in the browser |
| `REQUIRES_LOGIN` | Phase 1 | `true` if login must be attempted before testing |
| `KNOWLEDGE` | orchestrator | Parsed contents of the `chatbot-test` block |
| `LITE_MODE` | orchestrator | `true` if no issue/work item was provided |

## Outputs

`CATEGORY_RESULTS` — a structured list with one entry per test category:

```
{
  category: string,
  status: "PASSED" | "FAILED" | "BLOCKED" | "NOT_RUN",
  detail: string,
  qa_pairs: [                          // only present for Functional Accuracy category
    { question, must_contain, actual_response, duration_ms }
  ],
  probe_results: [                     // for Fallback, Continuity, Empty Input categories
    { probe, actual_response, duration_ms }
  ]
}
```

---

## Step 1: Detect Python and Check Chromium

```bash
PYTHON=$(command -v python3 2>/dev/null || command -v python)
$PYTHON -c "import playwright" 2>/dev/null || pip install playwright
$PYTHON -m playwright install chromium --with-deps 2>/dev/null || $PYTHON -m playwright install chromium
```

---

## Step 2: Translate Widget Hints

If `LITE_MODE=true` and `KNOWLEDGE` has no `widget` block, skip this step — no widget hints are available. Set `TRIGGER_SELECTOR`, `READY_SELECTOR`, and `RESPONSE_DONE_SELECTOR` to `null`.

Otherwise, run a short Playwright exploration script to capture the page's HTML structure, then use an LLM call to translate the three plain language hints into CSS selectors or XPath expressions:

- `KNOWLEDGE.widget.trigger_hint` → `TRIGGER_SELECTOR`
- `KNOWLEDGE.widget.ready_hint` → `READY_SELECTOR`
- `KNOWLEDGE.widget.response_done_hint` → `RESPONSE_DONE_SELECTOR`

If translation fails for any hint, use the fallback heuristic chain:
1. Send button re-enables: `button[type=submit]:not([disabled]), button.send:not([disabled])`
2. Typing indicator disappears: `.typing-indicator, .chat-loading, [class*="typing"]`
3. Input field re-enables: `input[type=text]:not([disabled]), textarea:not([disabled])`

---

## Step 2.5: Generate Continuity Probe

Before writing the test script, generate a topic-specific follow-up question to use in Category 5.

**If `KNOWLEDGE` has a `knowledge` array with at least one entry**, take the last question in the array and make a single LLM call:

```
Given that a user just asked an AI chatbot: "{last_question}"

Generate one short follow-up question (max 12 words) that:
- Is topically related to the original question
- Only makes sense if the chatbot remembers what it just answered
- Does not repeat the original question
- Is natural conversational English

Return only the follow-up question, no explanation.
```

Store the result as `CONTINUITY_PROBE`.

**If no `knowledge` array exists** (lite mode or no Q&A pairs), set:
`CONTINUITY_PROBE = "What else can you tell me about that topic?"`

---

## Step 3: Write and Execute Test Script

Create directory `_cbt_run/` and write `_cbt_run/test_script.py`.

The script must:
- Use **sync Playwright API** (not async)
- Open `TEST_URL` in headless Chromium
- Use a 30-second timeout for all `wait_for_selector` calls
- Log each result as a pipe-delimited line to `_cbt_run/log.txt`:
  `CATEGORY_RESULT|{category}|{status}|{detail}|{duration_ms}`
  `QA_RESULT|{index}|{question}|{actual_response}|{duration_ms}`
  `PROBE_RESULT|{category}|{probe_label}|{actual_response}|{duration_ms}`
- Always close the browser in a `finally` block

### Login (if REQUIRES_LOGIN=true)

Before opening the chatbot, attempt login using `username` (literal value) and the env var named in `password_env`:

```python
import os, json, pathlib

username = KNOWLEDGE["credentials"]["username"]                          # literal value from block
password_env_key = KNOWLEDGE["credentials"]["password_env"]             # e.g. "CHATBOT-TEST-PASSWORD"
password = os.environ.get(password_env_key, "")

# Fallback: read from ~/.chatbot-tester-creds.json if env var is empty
if not password:
    creds_file = pathlib.Path.home() / ".chatbot-tester-creds.json"
    if creds_file.exists():
        try:
            creds = json.loads(creds_file.read_text())
            password = creds.get(password_env_key, "")
        except Exception:
            pass

page.goto(TEST_URL)
try:
    username_field = page.wait_for_selector(
        'input[type=email], input[type=text][name*=user], input[name*=email], input[id*=user], input[id*=email]',
        timeout=5000
    )
    password_field = page.wait_for_selector(
        'input[type=password]',
        timeout=5000
    )
    username_field.fill(username)
    password_field.fill(password)
    page.keyboard.press('Enter')
    page.wait_for_load_state('networkidle', timeout=10000)
    log('CATEGORY_RESULT|login|PASSED|Generic login succeeded|' + str(duration))
except Exception as e:
    log('CATEGORY_RESULT|login|BLOCKED|Generic login failed: ' + str(e) + '|0')
    for category in ['ui_availability', 'functional_accuracy', 'fallback_handling',
                     'response_latency', 'conversation_continuity', 'empty_input_handling']:
        log(f'CATEGORY_RESULT|{category}|NOT_RUN|Login failed — category not executed|0')
    sys.exit(0)
```

### Category 1: UI Availability

```python
# 1. Open the page and wait for it to load
page.goto(TEST_URL)
page.wait_for_load_state('networkidle')

# 2. Find and click the trigger element
trigger = page.wait_for_selector(TRIGGER_SELECTOR, timeout=30000)
trigger.click()

# 3. Wait for the input field to be ready
page.wait_for_selector(READY_SELECTOR, timeout=30000)

# Verdict: PASSED if all three steps succeed
```

### Category 2: Functional Accuracy

**If `LITE_MODE=true` or `KNOWLEDGE` has no `knowledge` array**, skip this category and log:
`CATEGORY_RESULT|functional_accuracy|BLOCKED|Skipped — no Q&A pairs in test case|0`

Otherwise, for each Q&A pair in `KNOWLEDGE.knowledge`:

```python
start = time.time()
input_field = page.wait_for_selector(READY_SELECTOR, timeout=30000)
input_field.fill(question)
page.keyboard.press('Enter')

page.wait_for_selector(RESPONSE_DONE_SELECTOR, timeout=30000)

response_text = page.locator('[class*="bot-message"], [class*="assistant"], [data-role="bot"]').last.inner_text()
duration_ms = int((time.time() - start) * 1000)

log(f'QA_RESULT|{index}|{question}|{response_text}|{duration_ms}')
```

### Category 3: Fallback / Error Handling

Send two probes:
1. `"asdfghjkl zxcvbnm qwerty"` — pure gibberish
2. `"What is the capital of Mars?"` — out-of-scope question

For each probe, capture the bot response and verify:
- Response is non-empty
- Response does not contain a raw exception, stack trace, or `500` / `error` indicators

### Category 4: Response Latency

Record `duration_ms` for each Q&A pair message send (already captured in Category 2). Compute the average. The category PASSes if all responses complete within 30 seconds. Log the average latency in `detail`.

If `LITE_MODE=true` and no Q&A pairs were run, measure latency on the fallback probes instead.

### Category 5: Conversation Continuity

After at least one message has been sent (Q&A pair or fallback probe), send `CONTINUITY_PROBE` — the topic-specific follow-up generated in Step 2.5.

Log the probe text alongside the response so the judge can evaluate relevance:
`PROBE_RESULT|conversation_continuity|{CONTINUITY_PROBE}|{actual_response}|{duration_ms}`

### Category 6: Empty Input Handling

```python
input_field = page.wait_for_selector(READY_SELECTOR, timeout=30000)
input_field.fill('')
page.keyboard.press('Enter')
page.wait_for_timeout(3000)
# Verify: no crash, no empty error screen, page is still interactive
```

Verify the input field is still present and interactable after the empty submission.

---

## Step 4: Execute Script

```bash
$PYTHON _cbt_run/test_script.py 2>&1 | tee _cbt_run/execution.log
```

---

## Step 5: Parse Log

Read `_cbt_run/log.txt`. Parse each pipe-delimited line into the `CATEGORY_RESULTS` structure.

**If the login entry has status `BLOCKED`:** all 6 categories will be `NOT_RUN`. Skip Phase 3 entirely — there are no responses to judge. Pass `CATEGORY_RESULTS` directly to `skills/post-test-report/SKILL.md`. The overall verdict is `BLOCKED`.

For any FAILED or BLOCKED category, include the error detail captured from the exception or timeout in the `detail` field of `CATEGORY_RESULTS`.

---

## Step 6: Clean Up

```bash
rm -rf _cbt_run/
```

Always run this step, even if the script failed.

---

## Completion

Hand off to `skills/judge-responses/SKILL.md` with `CATEGORY_RESULTS` and `KNOWLEDGE` in scope.
