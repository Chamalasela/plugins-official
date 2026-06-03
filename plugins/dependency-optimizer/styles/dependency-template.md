# Dependency Optimization Report Template

This template defines the structure for the compiled dependency optimization report. The orchestrator agent must follow this format exactly when compiling findings from sub-agents to generate the automated PR description.

---

## Dependency Optimization Report

**Target Workspace/Manifest:** [e.g., package.json, requirements.txt, or Root Workspace]
**Ecosystem Detected:** [e.g., Node.js (npm), Python (Poetry), Rust (Cargo)]
**Dependencies Scanned:** [total count] | **[updates-applied]** Automated Fixes | **[manual-fixes]** Actions Required
**Health Status:** one of — `SECURE` | `FIXES AVAILABLE` | `MANUAL INTERVENTION`

> The Health Status string MUST be one of the three values above, written in uppercase, with no decoration. This determines whether an automated PR is opened and how it is labeled in the repository.
>
> Mapping guide:
> - `SECURE` — No CVEs, no outdated packages, no unused deps, all licenses permissive. Report posted as a comment only; no PR is created.
> - `FIXES AVAILABLE` — Outdated packages or non-breaking vulnerabilities found and successfully auto-patched. A Pull Request is created automatically.
> - `MANUAL INTERVENTION` — High-risk CVEs, major version breaking changes, or severe licensing violations detected that require human engineering decisions.

---

### Summary
[2-3 sentence overall assessment of the project's dependency health, including total estimated bundle size or attack surface reduced.]
---

### Automated Fixes Applied
> Dependencies that were safely updated to patch vulnerabilities or minor version lag in this automated Pull Request.

- [x] `path/to/manifest.<ext>` — **package-name** upgraded from `current_version` to `target_version`
  ```
  // Before
  "package-name": "current_version"

  // After (Patched)
  "package-name": "target_version"
  ```

*(If none: "No automated fixes applied.")*

---

### Critical Issues Requiring Attention (Manual Intervention)
> Blocking issues that could not be safely auto-patched due to major breaking changes, missing peer dependencies, or severe legal/license conflicts.

- [ ] path/to/manifest.<ext> — package-name@current_version -> target_version [CRITICAL] Why: [Description of the blocking CVE, severe technical debt, or GPL/copyleft violation]
  ```
    Manual upgrade command or refactoring steps needed
  ```

(If none: "No critical manual issues found.")

---

### Warnings & Technical Debt (Should Address)
> Non-blocking but important tracking — minor version drift, deprecated packages, or unoptimized transitives.

- [ ] path/to/manifest.<ext> — package-name is X minor versions behind upstream. Consider bumping to avoid future drift.

---

### Optimization & Tree-Shaking Suggestions
> Nice-to-have cleanups — dead/unused dependencies detected, or heavy packages that can be swapped for lighter alternatives.

- [ ] package-name is installed but no imports were detected in the codebase. Safe to prune to save X KB/MB of bundle size.

---

### Optimization Details

#### Vulnerability & Security Scan
[Summary from vulnerability-scanner: patched CVEs, CVSS scores, remaining security risks]

#### Version & Release Tracking
[Summary from version-updater: SemVer analysis, major/minor delta tracking, breaking change risk assessments]

#### Bloat & Performance Impact
[Summary from bloat-analyzer: unused packages, duplicate transitive versions, bundle size delta]

#### License & Policy Compliance
[Summary from license-auditor: legal compatibility, copyleft alerts, corporate policy compliance]

---

### Scanned Manifests & Manifest Health

| Manifest / Lockfile | Ecosystem | Risk Impact | Notes |
|---------------------|-----------|-------------|-------|
| `package.js` | Node.js | 🔴 High | Critical CVE patched; major upgrade pending |
| `cargo.toml` | Rust | 🟢 Low | All dependencies secure and optimized |
