---
name: optimize-dependencies
description: Run a full dependency optimization — scans for CVEs, version drift, bloat, and license issues, then automatically creates a PR with safe fixes. Usage: /optimize-dependencies
disable-model-invocation: true
---

Run a comprehensive dependency optimization for the current project.

Use the **orchestrator** agent to perform a full dependency optimization. The orchestrator will:

1. Detect the hosting platform from `git remote get-url origin`
2. Detect the package ecosystem from manifest files (package.json, requirements.txt, Cargo.toml, etc.)
3. Post a "scan in progress" notification if a PR context is available
4. Run four specialized sub-agent analyses in parallel:
   - **vulnerability-scanner** — CVEs, security advisories, deprecated packages
   - **version-updater** — SemVer drift, patch/minor/major update risk
   - **bloat-analyzer** — Unused dependencies, duplicate transitive packages, bundle size
   - **license-auditor** — Copyleft detection, license compatibility, corporate policy
5. Compile all findings into a structured report (see `styles/dependency-template.md`)
6. If safe fixes are available: create a new branch, apply patch/minor updates, remove unused deps, open a PR
7. Post the full report to the detected platform

**Health status outcomes:**
- `SECURE` — No issues found; report posted as a comment
- `FIXES AVAILABLE` — Safe updates applied automatically; a PR is opened
- `MANUAL INTERVENTION` — Critical CVEs or major upgrades require human review

If no argument is given, scan the **current working directory**.
