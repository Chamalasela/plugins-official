# chatbot-tester — Setup Guide

## Prerequisites

### 1. Python 3.10+

```bash
python3 --version   # must be 3.10 or higher
```

Install from [python.org](https://python.org) if not present.

### 2. Playwright Python Package

```bash
pip install playwright
playwright install chromium
```

### 3. Platform CLI

**GitHub repos:**
```bash
# Install gh CLI
brew install gh            # macOS
winget install GitHub.cli  # Windows
apt install gh             # Linux

# Authenticate
gh auth login
```

**Azure DevOps repos:**
```bash
# Set PAT with Work Items (Read/Write), Code (Read), Pull Requests (Read/Write)
export AZURE-DEVOPS-TOKEN=your_pat_here
```

---

## Knowledge File

Copy the example file and fill in your values:

```bash
cp knowledge/chatbot-tester.example.json knowledge/chatbot-tester.json
```

Then edit `knowledge/chatbot-tester.json`:

### Widget Block (required)

Describe the chatbot widget in plain language. The plugin will translate these hints into Playwright selectors automatically on the first run and cache them.

```json
"widget": {
  "trigger_hint": "blue chat button in the bottom right corner",
  "ready_hint": "input field shows placeholder text 'Type your question...'",
  "response_done_hint": "send button becomes clickable again"
}
```

**Tips for writing good hints:**
- Describe visual characteristics: colour, position, icon, label text
- Describe state changes: "becomes clickable", "placeholder disappears", "spinner stops"
- Be specific about location: "bottom right corner", "left sidebar", "top of the page"

The translated selectors are cached in `widget._cached_selectors` after the first run — subsequent runs skip the translation step entirely.

### Credentials Block (optional)

If the chatbot requires login to access, add credentials. Use environment variable names, not raw values.

```json
"credentials": {
  "username_env": "TEST_USER",
  "password_env": "TEST_PASS"
}
```

Then set the env vars before running:
```bash
export TEST_USER=testuser@example.com
export TEST_PASS=your_test_password
```

The plugin attempts a generic form-based login. If your app uses SSO or OAuth, the login step will be marked BLOCKED with instructions.

### Knowledge Block (optional but recommended)

Define Q&A pairs the chatbot should answer correctly. Each pair has a question and a list of terms that must appear in the response.

```json
"knowledge": [
  {
    "question": "What are your opening hours?",
    "must_contain": ["9am", "5pm", "Monday"]
  },
  {
    "question": "How do I reset my password?",
    "must_contain": ["email", "reset link"]
  }
]
```

Without a `knowledge` block, the Functional Accuracy category is skipped and marked N/A.

---

## Running the Plugin

**Against a PR:**
```
/test-chatbot pr 42
```

**Against an issue:**
```
/test-chatbot issue 88
```

**Against an Azure DevOps work item:**
```
/test-chatbot wi 1234
```

**Against a direct URL (writes report locally):**
```
/test-chatbot https://staging.example.com
```

---

## Report Output

| Trigger | Report destination |
|---|---|
| PR/Issue/Work Item | Comment posted on the PR/issue |
| Direct URL | `chatbot-test-report.md` written in current directory |

---

## Troubleshooting

**BLOCKED: knowledge file not configured**
→ Create `knowledge/chatbot-tester.json` from the example file.

**BLOCKED: widget hints missing**
→ Add a `widget` block to your knowledge file with `trigger_hint`, `ready_hint`, and `response_done_hint`.

**BLOCKED: generic login failed**
→ Verify `TEST_USER` and `TEST_PASS` env vars are set. If your app uses SSO, the generic login approach is not supported in v1.

**BLOCKED: response timeout (30s)**
→ Your chatbot takes longer than 30 seconds to respond. Check if the app is running correctly. Consider simplifying your Q&A pairs for the test environment.

**Selectors not working after UI update**
→ Delete the `widget._cached_selectors` block from your knowledge file. The plugin will re-translate the plain language hints on the next run.
