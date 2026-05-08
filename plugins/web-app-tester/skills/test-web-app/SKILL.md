---
name: test-web-app
description: Runs web app behaviour verification for a GitHub PR or Issue. Finds a testable URL, executes a structured test plan via Playwright MCP, and posts a step-by-step test execution report as a GitHub comment.
triggers:
  - /test-web-app
---

# Skill: Test Web App

Triggers the **orchestrator** agent to run automated browser-based verification of web app behaviour for a given GitHub PR or Issue.

## Usage

```
/test-web-app [pr <n> | issue <n>]
```

## What It Does

1. Fetches all PR/issue content — description, comments, commits, and linked issues
2. Scans content for a testable URL (preview, staging, deploy URL)
3. Finds a structured test plan in comments or auto-generates one
4. Opens a fresh Playwright browser session and executes each step
5. Retries failed steps up to 3 times before marking them BLOCKED
6. Posts a structured test execution report as a GitHub comment with step-by-step results

## Output

- GitHub comment with test execution table (step | status)
- Screenshots attached for FAILED and BLOCKED steps
- Overall verdict: PASSED / FAILED / BLOCKED
