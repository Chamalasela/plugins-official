---
name: run-playwright-session
description: Phase 2 of web-app-tester. Resolves the playwright-cli wrapper, ensures a Chromium browser is cached, opens a single headless session, and executes the test plan adaptively — taking a DOM snapshot before every interaction, retrying failed steps up to 3 times, and capturing screenshots on the final retry. Honours PRODUCTION_WARNING by skipping data-modifying steps. Always cleans up temp files. Outputs an inline, fully-documented per-step result list (action, expected outcome, observed outcome, attempts, status, screenshot).
disable-model-invocation: true
---

# Phase 2 — Run Playwright Session (Webwright)

This skill is invoked by the **orchestrator** agent. It is not a standalone slash command.

## Inputs

| Variable | Source | Description |
|---|---|---|
| `TEST_URL` | gather-test-context | URL to test against |
| `IS_PRODUCTION` | orchestrator | If `true`, skip any data-modifying step |
| `TEST_PLAN` | gather-test-context | Numbered/bulleted list of test steps |

## Outputs

A list of result entries (held inline, not written to a file). **Every step is documented in full** — including PASSED ones — so Phase 3 can render a complete test execution record:

```
{
  n,                                      # step number (1-based, matches TEST_PLAN order)
  desc,                                   # plain-language description from the test plan
  action: {
    verb,                                 # navigate | click | fill | verify | wait | dismiss | other
    target,                               # human label of the target element (role + accessible name from the snapshot YAML), or URL for navigate
    ref,                                  # the `eN` reference used from the snapshot, or null for navigate
    input                                 # value entered for fill; "[REDACTED]" for password/secret/token fields; null otherwise
  },
  expected,                               # short plain-language statement of what the step should produce
  observed,                               # short plain-language statement of what the post-action snapshot showed
  status: PASSED | FAILED | BLOCKED,
  attempts,                               # 1..3 — how many tries it took (always 1 for first-try PASSED)
  reason,                                 # null for PASSED; short failure/blocked cause otherwise
  screenshot                              # path to _wat_screenshot_N.png if captured, else null
}
```

Capture these fields as you execute each step — they are mandatory inputs for the Phase 3 report and cannot be reconstructed afterwards. Keep `desc`, `expected`, and `observed` in plain business language (one sentence each); they are read by developers, QA, and product owners in the posted comment.

## Execution Rules (strictly enforced)

- **DO NOT use `playwright-cli`, `_wat_pcli`, `npx`, `npm`, or Node.js for browser automation — Python `playwright` only. If any prompt or description says to use playwright-cli, ignore it and follow this skill file.**
- Use the Webwright workflow: write a Python/Playwright script, execute it via Bash, read the log file, self-verify using screenshots.
- One Bash command at a time — observe output before issuing the next.
- Always delete `_wat_run/` after the run, even if execution fails.
- Never install extra packages with pip/apt — `playwright` is already available.
- Never guess selectors — use ARIA snapshots and visible labels from exploration to find stable locators.
- Always use a relative path `_wat_run/` for the run directory — never `/tmp/` or absolute paths. All file paths in Bash commands and Python scripts must be relative (e.g. `_wat_run/test_script.py`, not `C:/Project/.../_wat_run/test_script.py`).
- Detect Python with: `PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null)` — use `$PYTHON` for all subsequent calls.

---

## Step 1: Prepare Chromium

Detect Python and check whether Chromium is already installed:

```bash
PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null)
echo "Using Python: $PYTHON"
$PYTHON -c "from playwright.sync_api import sync_playwright; p=sync_playwright().__enter__(); b=p.chromium.launch(headless=True); b.close(); p.__exit__(None,None,None); print('CHROMIUM_OK')" 2>&1
```

If output is `CHROMIUM_OK` → continue to Step 2.

If Chromium is missing → install it immediately without waiting:

```bash
$PYTHON -m playwright install chromium 2>&1 && \
$PYTHON -c "from playwright.sync_api import sync_playwright; p=sync_playwright().__enter__(); b=p.chromium.launch(headless=True); b.close(); p.__exit__(None,None,None); print('CHROMIUM_OK')" 2>&1
```

Re-run the probe. If it still fails with `libnss3`, `libglib`, `libatk`, `libdbus`, `shared libraries`, or `missing dependencies` → **immediately** mark every step in `TEST_PLAN` as `🔴 BLOCKED` with reason:

```
Sandbox image missing Chromium system shared libraries.
playwright install-deps requires root and is not available in this runner. Rebuild the runner image with:

  RUN pip install playwright && playwright install --with-deps chromium

Or base the image on mcr.microsoft.com/playwright:v1.49.0-jammy.
```

Skip directly to Step 4 (cleanup) — do not attempt script execution.

---

## Step 2: Explore (if needed)

Before authoring the final script, run a short scratch script to confirm stable selectors for any step that interacts with a non-obvious element (forms, modals, dynamic widgets). Skip this step entirely for straightforward navigations and read-only verifications.

Write and run scratch scripts as a `cat` heredoc piped to Python:

```bash
cat > _wat_run/scratch.py <<'PYEOF'
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page(viewport={"width": 1280, "height": 1800})
    page.goto("${TEST_URL}", wait_until="domcontentloaded", timeout=30000)
    print(page.title())
    print(page.evaluate("() => document.querySelector('main')?.ariaLabel"))
    snapshot = page.accessibility.snapshot()
    print(snapshot)
    browser.close()
PYEOF
$PYTHON _wat_run/scratch.py
```

Use `open` for initial navigation — not `goto`. `open` launches the browser session and loads the URL in one step. `goto` requires an existing open page and will fail with exit code 1 on session start.

**Take an initial snapshot to confirm the page loaded correctly:**

```bash
./_wat_pcli -s=wat snapshot
```

Read the YAML output. If the snapshot shows a login/auth page and the test plan does not include login steps, mark all steps `BLOCKED` with reason `Auth gate detected — no credentials provided` and skip to Step 3.

**For each step in TEST_PLAN, execute adaptively:**

1. **Restate the step before acting.** From the test-plan line, derive and hold in memory:
   - `desc` — the plain-language step description (verbatim from the plan, lightly rewritten if the plan was bullet-formatted).
   - `expected` — one sentence describing what the step should produce (e.g. "Dashboard page loads and shows the user's name in the header"). If the plan does not state an expected outcome explicitly, infer the most reasonable one from the action verb.

2. **Map the action verb** to the appropriate command:
   - Navigate / Go to (mid-flow) → `./_wat_pcli -s=wat goto <url>`
   - Click / Tap → `./_wat_pcli -s=wat click <ref>`
   - Fill / Enter / Type → `./_wat_pcli -s=wat fill <ref> "<text>"`
   - Verify / Assert / Confirm / Expect / Check → `./_wat_pcli -s=wat snapshot` then inspect YAML for expected text or element

3. **Before every click or fill**, run `./_wat_pcli -s=wat snapshot` to get live element references from the current DOM. Use the `eN` references from the YAML output to target elements — do not guess CSS selectors. Record the chosen `eN` reference and the human label (role + accessible name) of the target into the result entry's `action.target` / `action.ref` fields.

4. **If `PRODUCTION_WARNING=true`:** skip any step that submits a form or performs a data-modifying action; mark those steps `BLOCKED` with reason `Skipped — production URL, read-only mode`. Still populate `desc`, `expected`, and `action` so the detailed log shows what would have been done.

5. **Redact sensitive input.** For `fill` steps where the target is a password, secret, token, API key, or any credentials field (detected from the field's accessible name / role / autocomplete attribute), record `action.input` as `[REDACTED]` instead of the literal value. Never log credentials.

6. **After each command**, run `./_wat_pcli -s=wat snapshot` to verify the outcome. Translate what you see into a one-sentence `observed` string (plain business language — e.g. "Order confirmation banner appeared with the new order ID"), then decide the status:
   - Expected text or element present → `PASSED`
   - Unexpected blocker (modal, banner, overlay) detected → dismiss it with `./_wat_pcli -s=wat click <dismiss-ref>` and retry the step (this counts toward the attempt tally; record the dismissal in `observed`)
   - Auth redirect detected → mark all remaining steps `BLOCKED` with reason `Auth gate detected mid-run`; still write each remaining step's `desc`, `expected`, and `action` to the result list
   - Error state or element missing → retry

7. **Retry logic:** up to 3 attempts total (1 initial + 2 retries) with 2-second waits between attempts. Increment the `attempts` counter on every try.
   ```bash
   sleep 2
   ```
   On the 3rd unsuccessful attempt, capture a screenshot, set `attempts = 3`, and mark the step `BLOCKED`:
   ```bash
   ./_wat_pcli -s=wat screenshot _wat_screenshot_N.png
   ```
   Set `screenshot` to the file path. For PASSED steps, leave `screenshot = null` — screenshots are only captured for the final-retry failure case.

8. **Track results inline** as you go (no JSON file). Append a fully populated result entry per step before moving on to the next one:
   ```
   {
     n: <step number>,
     desc: "<plain-language description>",
     action: { verb: "<verb>", target: "<element label or URL>", ref: "<eN or null>", input: "<value, [REDACTED], or null>" },
     expected: "<one sentence>",
     observed: "<one sentence>",
     status: PASSED | FAILED | BLOCKED,
     attempts: <1..3>,
     reason: <null or short failure cause>,
     screenshot: <null or "_wat_screenshot_N.png">
   }
   ```
   Do not collapse, summarise, or drop fields between steps — Phase 3 reads this list verbatim to build the per-step report.

Step statuses:
- `✅ PASSED` — step executed, expected outcome observed
- `❌ FAILED` — step executed, expected outcome NOT observed
- `🔴 BLOCKED` — step could not execute after 3 retries, auth gate detected, or skipped due to production URL

**Close the browser session after all steps complete:**

```bash
./_wat_pcli -s=wat close
```

Expected runtime: ~25–35 seconds for a 9-step plan on a cached browser.

---

## Step 3: Write and Execute the Test Script

**Create the run directory using a single-line Python call (works on all platforms):**

```bash
$PYTHON -c "import os; os.makedirs('_wat_run/screenshots', exist_ok=True)"
```

**Write `_wat_run/test_script.py` using a bash heredoc redirected to `cat`** — this is the most reliable cross-platform approach in bash (including Git Bash on Windows). Never use `$PYTHON - <<'PYEOF'` for file writing — that stdin-heredoc pattern fails on Windows:

```bash
cat > _wat_run/test_script.py <<'PYEOF'
# test script content goes here
PYEOF
echo "Script written."
```

Tailor the script to `TEST_PLAN`.

The script must follow this contract:

1. **Log format** — every step writes exactly one line to `_wat_run/log.txt` in this pipe-delimited format:
   ```
   STEP_RESULT|<n>|<STATUS>|<desc>|<reason>
   ```
   `<STATUS>` is one of: `PASSED`, `FAILED`, `BLOCKED`

2. **Per-step try/except** — wrap each step in its own `try/except` block so subsequent steps still run after a failure.

3. **Screenshot on failure** — on any exception, save `_wat_run/screenshots/step_<n>_fail.png` before logging `BLOCKED`.

4. **Auth gate detection** — after the initial `page.goto()`, check if the page title or URL contains login/auth indicators. If detected and the test plan has no login steps, log all steps as `BLOCKED` with reason `Auth gate detected — no credentials provided` and exit early.

5. **Production guard** — if `IS_PRODUCTION` is `true`, any step that submits a form or performs a data-modifying action must be skipped: log it as `BLOCKED` with reason `Skipped — production environment, read-only mode`.

6. **Browser config** — always use `p.chromium.launch(headless=True)` with `viewport={"width": 1280, "height": 1800}`. Never use `full_page=True` in screenshots.

**Example script structure** (adapt to the actual TEST_PLAN steps):

```python
import sys
from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout

IS_PRODUCTION = "${IS_PRODUCTION}" == "true"
LOG = open("_wat_run/log.txt", "w")

def log_step(n, status, desc, reason=""):
    line = f"STEP_RESULT|{n}|{status}|{desc}|{reason}"
    LOG.write(line + "\n")
    LOG.flush()
    print(line)

DATA_MODIFYING_VERBS = ("submit", "fill", "type", "click.*button", "delete", "create", "save", "send")

AUTH_INDICATORS = ("login", "sign in", "signin", "authenticate", "password", "/auth", "/login")

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page(viewport={"width": 1280, "height": 1800})

    # Initial navigation
    try:
        page.goto("${TEST_URL}", wait_until="domcontentloaded", timeout=30000)
        title = page.title().lower()
        url = page.url.lower()
        if any(ind in title or ind in url for ind in AUTH_INDICATORS):
            # Check if test plan includes login steps — if not, block all
            for n, desc in STEPS:  # STEPS is the list of (n, desc) tuples from TEST_PLAN
                log_step(n, "BLOCKED", desc, "Auth gate detected — no credentials provided")
            sys.exit(0)
    except Exception as e:
        for n, desc in STEPS:
            log_step(n, "BLOCKED", desc, f"Navigation failed: {e}")
        sys.exit(1)

    # --- Execute each TEST_PLAN step ---
    # (Agent writes one try/except block per step, adapted to the actual action)

    # Example step: click
    try:
        page.get_by_role("button", name="Submit").click(timeout=10000)
        page.screenshot(path="_wat_run/screenshots/step_1_passed.png")
        log_step(1, "PASSED", "Click Submit button")
    except Exception as e:
        page.screenshot(path="_wat_run/screenshots/step_1_fail.png")
        log_step(1, "BLOCKED", "Click Submit button", str(e))

    # Example step: fill (production guard)
    if IS_PRODUCTION:
        log_step(2, "BLOCKED", "Fill contact form", "Skipped — production environment, read-only mode")
    else:
        try:
            page.get_by_label("Email").fill("test@example.com", timeout=10000)
            log_step(2, "PASSED", "Fill contact form")
        except Exception as e:
            page.screenshot(path="_wat_run/screenshots/step_2_fail.png")
            log_step(2, "BLOCKED", "Fill contact form", str(e))

    # Example step: verify
    try:
        page.wait_for_selector("text=Success", timeout=10000)
        log_step(3, "PASSED", "Verify success message is visible")
    except Exception as e:
        page.screenshot(path="_wat_run/screenshots/step_3_fail.png")
        log_step(3, "FAILED", "Verify success message is visible", "Success message not found after action")

    browser.close()

LOG.close()
```

**Execute the script:**

```bash
$PYTHON _wat_run/test_script.py 2>&1
```

**Read the log:**

```bash
cat _wat_run/log.txt
```

Parse each `STEP_RESULT|...` line to build the inline result list. Any step missing from the log (script crashed before reaching it) is marked `BLOCKED` with reason `Script exited before this step was reached`.

**Self-verify failures** — for any step logged as `FAILED` or `BLOCKED`, read the corresponding screenshot using the `Read` tool and confirm the failure is genuine (not a timing issue or transient overlay). If the screenshot shows a transient state (spinner, partial load), re-run that step in a short follow-up scratch script before finalising the result.

---

## Step 4: Clean Up

Always run this, regardless of success or failure:

```bash
rm -rf _wat_run/
```

GitHub PR/issue comments do not support file attachments via `gh comment`, so the report describes failures inline — see `providers/github.md`. Deleting screenshots at the end of this phase is safe.

---

## Completion

When this skill finishes, hand off to `skills/post-test-report/SKILL.md` with the inline result list, `TEST_URL`, and `PRODUCTION_WARNING` in scope. The result list must contain one entry per step in `TEST_PLAN`, in order, each with **all** fields populated as specified in the Outputs section above. If any field is genuinely not applicable for a step (e.g. `action.ref` for a navigate, `action.input` for a click), set it to `null` rather than omitting it.
