---
name: run-playwright-session
description: Phase 2 of web-app-tester. Follows the Webwright workflow — writes an instrumented Python/Playwright script tailored to the test plan, executes it, reads the structured log to extract per-step results, and self-verifies failures against screenshots. Honours PRODUCTION_WARNING by embedding skip guards in the script. Always cleans up temp files. Outputs an inline list of per-step results.
disable-model-invocation: true
---

# Phase 2 — Run Playwright Session (Webwright)

This skill is invoked by the **orchestrator** agent. It is not a standalone slash command.

## Inputs

| Variable | Source | Description |
|---|---|---|
| `TEST_URL` | gather-test-context | URL to test against |
| `PRODUCTION_WARNING` | gather-test-context | If `true`, skip any data-modifying step |
| `TEST_PLAN` | gather-test-context | Numbered/bulleted list of test steps |

## Outputs

A list of result entries (held inline, not written to a file):

```
{ n, desc, status: PASSED|FAILED|BLOCKED, reason, action, duration_ms, screenshot }
```

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

Read the output to confirm page title, visible labels, and ARIA structure. Use this to identify stable locators before writing the final script.

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
   STEP_RESULT|<n>|<STATUS>|<desc>|<reason>|<action>|<duration_ms>
   ```
   `<STATUS>` is one of: `PASSED`, `FAILED`, `BLOCKED`
   `<action>` is a human-readable sentence of what Playwright did (e.g. `Clicked button 'Submit'`, `Filled 'Email' with 'test@example.com'`, `Navigated to https://...`, `Verified text 'Success' is visible`)
   `<duration_ms>` is the integer milliseconds the step took, measured with `time.time()` around the action block

2. **Per-step try/except** — wrap each step in its own `try/except` block so subsequent steps still run after a failure.

3. **Screenshot on failure** — on any exception, save `_wat_run/screenshots/step_<n>_fail.png` before logging `BLOCKED`.

4. **Auth gate detection** — after the initial `page.goto()`, check if the page title or URL contains login/auth indicators. If detected and the test plan has no login steps, log all steps as `BLOCKED` with reason `Auth gate detected — no credentials provided` and exit early.

5. **PRODUCTION_WARNING guard** — if `PRODUCTION_WARNING` is `true`, any step that submits a form or performs a data-modifying action must be skipped: log it as `BLOCKED` with reason `Skipped — production URL, read-only mode`.

6. **Browser config** — always use `p.chromium.launch(headless=True)` with `viewport={"width": 1280, "height": 1800}`. Never use `full_page=True` in screenshots.

**Example script structure** (adapt to the actual TEST_PLAN steps):

```python
import sys
import time
from playwright.sync_api import sync_playwright, TimeoutError as PWTimeout

PRODUCTION_WARNING = "${PRODUCTION_WARNING}" == "true"
LOG = open("_wat_run/log.txt", "w")

def log_step(n, status, desc, reason="", action="", duration_ms=0):
    line = f"STEP_RESULT|{n}|{status}|{desc}|{reason}|{action}|{duration_ms}"
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
    _start = time.time()
    try:
        page.get_by_role("button", name="Submit").click(timeout=10000)
        page.screenshot(path="_wat_run/screenshots/step_1_passed.png")
        log_step(1, "PASSED", "Click Submit button", action="Clicked button 'Submit'", duration_ms=int((time.time()-_start)*1000))
    except Exception as e:
        page.screenshot(path="_wat_run/screenshots/step_1_fail.png")
        log_step(1, "BLOCKED", "Click Submit button", str(e), action="Clicked button 'Submit'", duration_ms=int((time.time()-_start)*1000))

    # Example step: fill (PRODUCTION_WARNING guard)
    if PRODUCTION_WARNING:
        log_step(2, "BLOCKED", "Fill contact form", "Skipped — production URL, read-only mode", action="Filled 'Email' with test value")
    else:
        _start = time.time()
        try:
            page.get_by_label("Email").fill("test@example.com", timeout=10000)
            log_step(2, "PASSED", "Fill contact form", action="Filled 'Email' with 'test@example.com'", duration_ms=int((time.time()-_start)*1000))
        except Exception as e:
            page.screenshot(path="_wat_run/screenshots/step_2_fail.png")
            log_step(2, "BLOCKED", "Fill contact form", str(e), action="Filled 'Email' with 'test@example.com'", duration_ms=int((time.time()-_start)*1000))

    # Example step: verify
    _start = time.time()
    try:
        page.wait_for_selector("text=Success", timeout=10000)
        log_step(3, "PASSED", "Verify success message is visible", action="Verified text 'Success' is visible", duration_ms=int((time.time()-_start)*1000))
    except Exception as e:
        page.screenshot(path="_wat_run/screenshots/step_3_fail.png")
        log_step(3, "FAILED", "Verify success message is visible", "Success message not found after action", action="Verified text 'Success' is visible", duration_ms=int((time.time()-_start)*1000))

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

When this skill finishes, hand off to `skills/post-test-report/SKILL.md` with the inline result list, `TEST_URL`, and `PRODUCTION_WARNING` in scope.
