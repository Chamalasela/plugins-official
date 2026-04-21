# Platform Configuration

Setup guide for all credentials and CLI tools required by the incident-response plugin.

---

## Azure DevOps

### 1. Create a Personal Access Token (PAT)

1. Go to `https://dev.azure.com/{org}` → top-right avatar → **Personal Access Tokens**
2. Click **+ New Token**
3. Set the following scopes:

| Scope | Permission |
|---|---|
| Work Items | Read & Write |
| Build | Read |
| Release | Read |

4. Set an expiry and copy the token immediately.

### 2. Set the environment variable

```bash
export AZURE_DEVOPS_TOKEN="{your-pat}"
```

For CI/CD pipelines, add as a secret variable in your pipeline definition and reference it as `$(AZURE_DEVOPS_TOKEN)` (ADO) or `${{ secrets.AZURE_DEVOPS_TOKEN }}` (GitHub Actions).

---

## GitHub

### Option A — gh CLI (recommended for local use)

```bash
# Install gh CLI: https://cli.github.com
gh auth login
```

Follow the interactive prompts to authenticate via browser or token.

### Option B — Environment variable (CI/CD)

```bash
export GITHUB_TOKEN="{github-personal-access-token}"
```

Token must have `repo` scope (for private repos) or `public_repo` scope (for public repos). GitHub Actions workflows automatically have `GITHUB_TOKEN` available via `${{ secrets.GITHUB_TOKEN }}`.

---

## Azure Monitor — Log Analytics

Required for the log-analyzer agent to run KQL queries.

### 1. Install the Azure CLI

```bash
# macOS
brew install azure-cli

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Windows
winget install -e --id Microsoft.AzureCLI
```

### 2. Authenticate

**For local use:**
```bash
az login
```

**For CI/CD (service principal):**
```bash
# Create service principal
az ad sp create-for-rbac --name "incident-response-agent" --role "Log Analytics Reader" \
  --scopes "/subscriptions/{subscription-id}/resourceGroups/{rg-name}"

# Output: appId, password, tenant
export AZURE_CLIENT_ID="{appId}"
export AZURE_CLIENT_SECRET="{password}"
export AZURE_TENANT_ID="{tenant}"

# Authenticate with the service principal
az login --service-principal \
  --username "$AZURE_CLIENT_ID" \
  --password "$AZURE_CLIENT_SECRET" \
  --tenant "$AZURE_TENANT_ID"
```

### 3. Assign required roles

| Role | Scope | Purpose |
|---|---|---|
| `Log Analytics Reader` | Log Analytics Workspace | Run `az monitor log-analytics query` |
| `Monitoring Reader` | Resource Group or Subscription | Read metrics via `az monitor metrics list` |

```bash
# Assign Log Analytics Reader
az role assignment create \
  --assignee "{service-principal-object-id}" \
  --role "Log Analytics Reader" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.OperationalInsights/workspaces/{workspace-name}"

# Assign Monitoring Reader
az role assignment create \
  --assignee "{service-principal-object-id}" \
  --role "Monitoring Reader" \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{rg-name}"
```

### 4. Set the workspace ID

```bash
# Find your workspace ID
az monitor log-analytics workspace list --query "[].{name:name, customerId:customerId}" --output table

export LOG_ANALYTICS_WORKSPACE_ID="{customerId from above}"
```

---

## Optional Environment Variables

| Variable | Purpose | Default |
|---|---|---|
| `INCIDENT_WINDOW_HOURS` | Hours before incident start to search for deployments | `2` |
| `METRICS_SOURCE` | Path to a JSON metrics snapshot (skips `az monitor metrics list`) | unset |

---

## Verifying Your Setup

Run the prerequisite check directly:

```bash
cd plugins/incident-response
bash hooks/validate-prerequisites.sh
echo "Exit code: $?"
```

Exit code `0` means all required credentials are in place for the detected platform.
