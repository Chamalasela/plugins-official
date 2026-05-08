# Setup Guide

The `web-app-tester` plugin has two prerequisites: Node.js and the GitHub CLI. No MCP server configuration is required.

---

## Node.js 20+

Node.js is required to execute the Playwright test script that the plugin generates at runtime.

Verify:
```bash
node --version   # must be v20 or higher
```

Install from [nodejs.org](https://nodejs.org) if not present.

### Playwright Browser Caching

On the first test run the plugin installs Chromium (~150 MB) via npx. This takes ~30–60 seconds.

**Every subsequent run skips the install entirely** — the plugin checks for a cached browser before attempting any download. After the first run, browser startup adds ~0 seconds.

For the **Xianix platform**: request that `playwright` and Chromium be pre-installed in `99xio/xianix-executor:latest`. This eliminates the first-run install cost and makes every run start at full speed.

---

## GitHub CLI

The plugin uses `gh` to read PR/issue content and post the results comment.

### Installation

| Platform | Command |
|---|---|
| macOS | `brew install gh` |
| Windows | `winget install GitHub.cli` |
| Linux (Debian/Ubuntu) | `apt install gh` |

### Authentication

```bash
gh auth login
```

Or set the environment variable:

```bash
export GITHUB_TOKEN=ghp_your_token_here
```

### Token Permissions

| Permission | Access | Why it's needed |
|---|---|---|
| **Metadata** | Read | Resolve repository owner and name |
| **Issues** | Read & Write | Fetch issue content and post result comments |
| **Pull requests** | Read & Write | Fetch PR content and post result comments |

---

## Troubleshooting

**`node: command not found`**
Install Node.js 20+ from [nodejs.org](https://nodejs.org) and ensure it is on your PATH.

**`gh: command not found`**
Install the `gh` CLI using the instructions above.

**`gh auth status` fails**
Run `gh auth login` or export `GITHUB_TOKEN` with a valid personal access token.

**First run is slow (~60s)**
This is normal — Playwright Chromium is being downloaded and cached. All subsequent runs skip this step.
