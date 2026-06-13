---
name: post-test-report
description: Phase 4 of chatbot-tester. Computes the overall verdict, composes the report strictly per styles/report-template.md, and posts it as an issue/work item comment (GitHub or Azure DevOps) or writes it to chatbot-test-report.md for direct URL runs.
disable-model-invocation: true
---

# Phase 4 — Post Test Report

This skill is invoked by the **orchestrator** agent. It is not a standalone slash command.

## Inputs

| Variable | Source | Description |
|---|---|---|
| `JUDGED_RESULTS` | Phase 3 | Full category results with verdicts and reasoning |
| `TEST_URL` | Phase 1 | The URL that was tested |
| `ENTRY_TYPE` | orchestrator | `issue`, `wi`, or `url` |
| `ENTRY_ID` | orchestrator | Issue number, work item ID, or the direct URL |
| `PLATFORM` | orchestrator | `GitHub`, `AzureDevOps`, or `DirectURL` |
| `LITE_MODE` | orchestrator | `true` if no issue/work item was provided |

---

## Step 1: Compute Overall Verdict

Compute the overall verdict using the Overall Verdict table in `docs/verdict-logic.md`.

---

## Step 2: Compose Report

Build the report body strictly per `styles/report-template.md`. Do not add content outside the defined structure.

---

## Step 3: Post or Write Report

**GitHub (`ENTRY_TYPE=issue`):**
```bash
gh issue comment ${ENTRY_ID} --repo ${GITHUB_OWNER}/${GITHUB_REPO} --body "${REPORT_BODY}"
```

**Azure DevOps (`ENTRY_TYPE=wi`):** see `providers/azure-devops.md` — Posting the Test Report.

**Direct URL (`ENTRY_TYPE=url`):**

Write the report body to `chatbot-test-report.md` in the current working directory:
```bash
cat > chatbot-test-report.md << 'REPORT'
{REPORT_BODY}
REPORT
```

Then output one line to terminal:
```
Report written to chatbot-test-report.md
```

### If posting fails (GitHub or Azure DevOps only)

If the `gh` or `curl` command exits with a non-zero status:

1. Write the report to `chatbot-test-report.md` in the current working directory (same format as the direct URL path above).
2. Output this warning line:
   ```
   chatbot-tester WARNING: failed to post report to {PLATFORM} — report written to chatbot-test-report.md instead. Error: {error_output}
   ```
3. Continue to the Completion step — do not abort.

---

## Completion

Output the final confirmation line:

```
chatbot-tester complete for {ENTRY_TYPE} {ENTRY_ID_OR_URL}: {OVERALL_VERDICT} — {PASSED_COUNT}/{TOTAL_CATEGORIES} categories passed
```
