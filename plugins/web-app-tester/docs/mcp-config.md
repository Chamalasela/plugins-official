# MCP Configuration: Playwright

The `web-app-tester` plugin bundles the **Playwright MCP server** directly in its `plugin.json` manifest. Claude Code starts the server automatically when the plugin is enabled and stops it when the plugin is disabled — no manual configuration file edits are required.

---

## How It Works

The `mcpServers` field in `.claude-plugin/plugin.json` declares the server:

```json
"mcpServers": {
  "playwright": {
    "command": "npx",
    "args": ["@playwright/mcp@latest"]
  }
}
```

When you enable the plugin, Claude Code:
1. Launches `npx @playwright/mcp@latest` as a managed subprocess
2. Makes all `mcp__playwright__*` tools available to the orchestrator agent
3. Lists the server in `/mcp` with a plugin-provided indicator

When you disable the plugin, the server stops automatically.

You do **not** need to edit `claude_desktop_config.json`. The Playwright server is fully managed by the plugin lifecycle.

---

## Prerequisites

Node.js 18+ and npm must be available in the runtime environment. Verify with:

```bash
node --version   # must be 18 or higher
npx --version
```

The Playwright MCP package is downloaded on first use via `npx` — no separate install step is needed.

---

## Verifying the MCP Server

After enabling the plugin, type `/mcp` in the Claude Code chat. The `playwright` server should appear in the list marked as plugin-provided. If it does not appear, check that `npx` is installed and accessible on your `PATH`.

---

## GitHub CLI

The plugin also requires the `gh` CLI for reading PR/issue content and posting comments.

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

**`playwright` server not showing in `/mcp`**
- Ensure Node.js 18+ is installed and `npx` is on your `PATH`
- Run `npx @playwright/mcp@latest --version` directly to confirm it installs without error
- Reload the plugin with `/reload-plugins` if you enabled it mid-session

**`gh: command not found`**
- Install the `gh` CLI using the instructions above and ensure it is on your `PATH`

**`gh auth status` fails**
- Run `gh auth login` to authenticate, or export `GITHUB_TOKEN` with a valid personal access token
