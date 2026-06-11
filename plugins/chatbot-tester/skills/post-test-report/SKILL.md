---
name: post-test-report
description: Phase 4 of chatbot-tester. Computes the overall verdict, composes the report strictly per styles/report-template.md, and posts it as a PR/issue comment (GitHub or Azure DevOps) or writes it to chatbot-test-report.md for direct URL runs.
disable-model-invocation: true
---

# Phase 4 — Post Test Report

This skill is invoked by the **orchestrator** agent. It is not a standalone slash command.

## Inputs

| Variable | Source | Description |
|---|---|---|
| `JUDGED_RESULTS` | Phase 3 | Full category results with verdicts and reasoning |
| `TEST_URL` | Phase 1 | The URL that was tested |
| `ENTRY_TYPE` | orchestrator | `pr`, `issue`, `wi`, or `url` |
| `ENTRY_ID` | orchestrator | PR number, issue number, or work item ID |
| `PLATFORM` | orchestrator | `GitHub`, `AzureDevOps`, or `DirectURL` |

---

## Step 1: Compute Overall Verdict

| Condition | Overall Verdict |
|---|---|
| All categories PASSED | **PASSED** |
| Any category PARTIAL, no FAILED or BLOCKED | **PARTIAL** |
| Any category FAILED or BLOCKED | **FAILED** |

---

## Step 2: Compose Report

Build the report body strictly per `styles/report-template.md`. Do not add content outside the defined structure.

---

## Step 3: Post or Write Report

**GitHub (`ENTRY_TYPE=pr`):**
```bash
gh pr comment ${ENTRY_ID} --repo ${REPO} --body "${REPORT_BODY}"
```

**GitHub (`ENTRY_TYPE=issue`):**
```bash
gh issue comment ${ENTRY_ID} --repo ${REPO} --body "${REPORT_BODY}"
```

**Azure DevOps (`ENTRY_TYPE=pr`):** see `providers/azure-devops.md` — Posting a PR Thread Comment.

**Azure DevOps (`ENTRY_TYPE=wi`):** see `providers/azure-devops.md` — Posting a Work Item Comment.

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

---

## Completion

Output the final confirmation line:

```
chatbot-tester complete for {ENTRY_TYPE} {ENTRY_ID_OR_URL}: {OVERALL_VERDICT} — {PASSED_COUNT}/{TOTAL_CATEGORIES} categories passed
```
