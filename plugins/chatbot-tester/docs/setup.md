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

**GitHub issues:**
```bash
# Install gh CLI
brew install gh            # macOS
winget install GitHub.cli  # Windows
apt install gh             # Linux

# Authenticate
gh auth login
```

**Azure DevOps work items:**
```bash
# Set PAT with Work Items (Read/Write) permissions
export AZURE-DEVOPS-TOKEN=your_pat_here
```

### 4. Test Password Secret

Store the test account password in **Xianix Agentri Studio Secrets** with the key `CHATBOT-TEST-PASSWORD`. The plugin reads it at runtime via the env var name declared in the test case block.

---

## Creating a Test Case

Add a `chatbot-test` fenced code block to a **GitHub issue** or **Azure DevOps work item** body. The plugin reads it automatically — no local files needed.

````
```chatbot-test
{
  "url": "https://your-app-url.com",
  "widget": {
    "trigger_hint": "description of how to open the chatbot",
    "ready_hint": "description of when the input field is ready",
    "response_done_hint": "description of when the bot has finished responding"
  },
  "credentials": {
    "username": "test@example.com",
    "password_env": "CHATBOT-TEST-PASSWORD"
  },
  "knowledge": [
    {
      "question": "What are your opening hours?",
      "must_contain": ["9am", "5pm", "Monday"]
    }
  ]
}
```
````

### Widget Block (required)

Describe the chatbot widget in plain language. The plugin translates these hints into Playwright selectors on each run.
Describe the chatbot widget in plain language. The plugin translates these hints into Playwright selectors on each run.

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

### Credentials Block (optional)

If the chatbot requires login, add the username and a reference to the secret key holding the password.
If the chatbot requires login, add the username and a reference to the secret key holding the password.

```json
"credentials": {
  "username": "test@example.com",
  "password_env": "CHATBOT-TEST-PASSWORD"
}
```

`username` is the literal login email. `password_env` is the name of the Xianix Agentri Studio Secret key — never put the password value here.
`username` is the literal login email. `password_env` is the name of the Xianix Agentri Studio Secret key — never put the password value here.

### Knowledge Block (optional)
### Knowledge Block (optional)

Define Q&A pairs the chatbot should answer correctly.
Define Q&A pairs the chatbot should answer correctly.

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

Without a `knowledge` block, Functional Accuracy is skipped.
Without a `knowledge` block, Functional Accuracy is skipped.

---

## Running the Plugin

**Against a GitHub issue (full test):**
**Against a GitHub issue (full test):**
```
/test-chatbot https://github.com/owner/repo/issues/42
/test-chatbot https://github.com/owner/repo/issues/42
```

**Against an Azure DevOps work item (full test):**
**Against an Azure DevOps work item (full test):**
```
/test-chatbot https://dev.azure.com/org/project/_workitems/edit/1234
/test-chatbot https://dev.azure.com/org/project/_workitems/edit/1234
```

**Against a direct URL (lite mode — UI tests only):**
**Against a direct URL (lite mode — UI tests only):**
```
/test-chatbot https://staging.example.com
```

---

## Report Output

| Trigger | Report destination |
|---|---|
| GitHub issue | Comment posted on the issue |
| Azure DevOps work item | Comment posted on the work item |
| GitHub issue | Comment posted on the issue |
| Azure DevOps work item | Comment posted on the work item |
| Direct URL | `chatbot-test-report.md` written in current directory |

---

## Troubleshooting

**BLOCKED: no chatbot-test block found**
→ Add a `chatbot-test` fenced code block to the issue/work item body. See the template above.
**BLOCKED: no chatbot-test block found**
→ Add a `chatbot-test` fenced code block to the issue/work item body. See the template above.

**BLOCKED: missing required fields**
→ The block was found but `url`, `widget.trigger_hint`, `widget.ready_hint`, or `widget.response_done_hint` is missing. Add the missing fields.
**BLOCKED: missing required fields**
→ The block was found but `url`, `widget.trigger_hint`, `widget.ready_hint`, or `widget.response_done_hint` is missing. Add the missing fields.

**BLOCKED: generic login failed**
→ Verify `CHATBOT-TEST-PASSWORD` is set in Xianix Agentri Studio Secrets and matches the `password_env` value in your test case. If your app uses SSO or OAuth, the generic login approach is not supported in v2.

**BLOCKED: response timeout (30s)**
→ Your chatbot takes longer than 30 seconds to respond. Check if the app is running correctly.
→ Your chatbot takes longer than 30 seconds to respond. Check if the app is running correctly.

**Widget not found**
→ Review your `trigger_hint`. Be more specific about the element's visual appearance and position on the page.
**Widget not found**
→ Review your `trigger_hint`. Be more specific about the element's visual appearance and position on the page.
