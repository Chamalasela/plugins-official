---
name: test-chatbot
description: Verify AI chatbot behaviour in a web application. Loads widget configuration from the plugin knowledge file, opens the chatbot via Playwright (headless Chromium), runs six test categories, judges Q&A accuracy with a batched LLM call, and posts a structured report. Usage: /test-chatbot [pr <n> | issue <n> | wi <id> | <url>]
argument-hint: [pr <n> | issue <n> | wi <id> | <url>]
---

Run automated AI chatbot verification for $ARGUMENTS.

## What This Does

Invokes the **orchestrator** agent to:

1. Resolve the target URL — from a PR/issue/work item or directly from the argument
2. Read the knowledge file (`knowledge/chatbot-tester.json`) for widget hints, credentials, and Q&A pairs
3. Open the web application in a headless Chromium browser and locate the chatbot widget
4. Run six test categories against the chatbot
5. Judge Q&A pair responses with a single batched LLM call
6. Post a structured report as a PR/issue comment, or write `chatbot-test-report.md` for direct URL runs

## Entry Points

| Entry Point | Example | What the agent does |
|---|---|---|
| **PR number** | `/test-chatbot pr 42` | Fetches PR content, scans for staging URL, runs chatbot tests |
| **Issue number** | `/test-chatbot issue 88` | Fetches issue content, scans for staging URL, runs chatbot tests |
| **Work item ID** | `/test-chatbot wi 1234` | Fetches Azure DevOps work item, scans for URL, runs chatbot tests |
| **Direct URL** | `/test-chatbot https://staging.example.com` | Uses URL directly, writes report to local markdown file |

## Test Categories

| Category | What is tested |
|---|---|
| **UI Availability** | Widget loads, trigger button works, input field is interactable |
| **Functional Accuracy** | Q&A pairs from knowledge file — bot answers judged by LLM |
| **Fallback Handling** | Gibberish and out-of-scope inputs — bot responds gracefully without crashing |
| **Response Latency** | Time from message sent to response complete |
| **Conversation Continuity** | Follow-up question retains context from previous response |
| **Empty Input Handling** | Blank message submission handled gracefully |

## Knowledge File

The plugin reads `knowledge/chatbot-tester.json` from the plugin directory. This file must exist before running.

```json
{
  "widget": {
    "trigger_hint": "blue chat button in the bottom right corner",
    "ready_hint": "input field shows placeholder text 'Type your question...'",
    "response_done_hint": "send button becomes clickable again"
  },
  "credentials": {
    "username_env": "TEST_USER",
    "password_env": "TEST_PASS"
  },
  "knowledge": [
    {
      "question": "What are your opening hours?",
      "must_contain": ["9am", "5pm", "Monday"]
    }
  ]
}
```

Copy `knowledge/chatbot-tester.example.json` to `knowledge/chatbot-tester.json` and fill in your values. See `docs/setup.md` for full configuration reference.

## Verdict Logic

| Condition | Overall Verdict |
|---|---|
| All categories passed | **PASSED** |
| Any Q&A pair PARTIAL, no FAIL | **PARTIAL** |
| Any category FAILED or BLOCKED | **FAILED** |

## Prerequisites

- Python 3.10+ available (`python3 --version`)
- `playwright` Python package installed (`pip install playwright && playwright install chromium`)
- Knowledge file configured at `knowledge/chatbot-tester.json`
- **GitHub repos:** `gh` CLI installed and authenticated
- **Azure DevOps repos:** `curl` available and `AZURE-DEVOPS-TOKEN` set
- **Login required:** `TEST_USER` and `TEST_PASS` env vars set if credentials declared in knowledge file

---

Starting chatbot test now...
