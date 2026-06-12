---
name: gather-test-context
description: Phase 1 of chatbot-tester. Validates the extracted test block, checks if login is required, and handles lite mode. TEST_URL and KNOWLEDGE are already set by the orchestrator before this phase runs.
disable-model-invocation: true
---

# Phase 1 — Gather Test Context

This skill is invoked by the **orchestrator** agent. It is not a standalone slash command.

## Inputs

| Variable | Source | Description |
|---|---|---|
| `TEST_URL` | orchestrator | URL of the app to test (from `KNOWLEDGE.url` or direct URL argument) |
| `KNOWLEDGE` | orchestrator | Parsed contents of the `chatbot-test` block (empty object for lite mode) |
| `LITE_MODE` | orchestrator | `true` if invoked with a direct URL and no issue/work item |

## Outputs

| Variable | Description |
|---|---|
| `REQUIRES_LOGIN` | `true` if credentials are declared in the knowledge block; otherwise `false` |
| `PHASE1_BLOCK` | Set to a reason string if the run must not proceed; otherwise unset |

---

## Step 1: Check Login Requirement

If `KNOWLEDGE` contains a `credentials` block with both `username` and `password_env` fields → set `REQUIRES_LOGIN=true`.

Otherwise → set `REQUIRES_LOGIN=false`.

If `REQUIRES_LOGIN=true`, verify the env var named in `password_env` is set:

```bash
PASSWORD_ENV_KEY="${KNOWLEDGE.credentials.password_env}"
if [ -z "${!PASSWORD_ENV_KEY:-}" ]; then
  PHASE1_BLOCK="Password env var '${PASSWORD_ENV_KEY}' is not set. Store the test password in Xianix Agentri Studio Secrets under that key and re-run."
fi
```

If `PHASE1_BLOCK` is set, do not proceed to Phase 2. The orchestrator will post a BLOCKED report and stop.

---

## Step 2: Lite Mode Notice

If `LITE_MODE=true`, log the following so it is included in the final report:

```
LITE_MODE_NOTICE: Functional Accuracy was skipped — no test case provided.
To run a full test, create a GitHub issue or Azure DevOps work item with a
chatbot-test block and re-run:
  /test-chatbot https://github.com/owner/repo/issues/<n>
  /test-chatbot https://dev.azure.com/org/project/_workitems/edit/<id>
```

---

## Completion

Hand off to `skills/run-playwright-session/SKILL.md` with `TEST_URL`, `REQUIRES_LOGIN`, `KNOWLEDGE`, `LITE_MODE` in scope.
