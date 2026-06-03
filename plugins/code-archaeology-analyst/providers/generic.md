# Provider: Generic / Plain Text

Use this provider when:

- The git remote does not match GitHub or Azure DevOps
- The user supplies the target path directly via command arguments
- API posting is otherwise not available

## Behaviour

In generic mode the analysis is **not posted to a remote platform**. All output is written to local files so it can be consumed by an external process, CI system, or human operator.

---

## Input

In generic mode, the target path comes from the command arguments:

```
/code-archaeology [path] [--no-overlay] [--no-coverage]
```

If no path is specified, default to `.` (the current working directory).

There is no issue or work item to fetch — proceed directly to the codebase survey.

---

## Output Files

All output is written to the `ai-dlc/` directory at the repository root (or current working directory):

| File | Description |
|---|---|
| `ai-dlc/code-archaeology-analysis.md` | Full 8-section completion report |
| `ai-dlc/rules/codebase-rules.md` | Directive rules for AI assistants |
| `ai-dlc/guidelines/forbidden-zones.md` | Areas requiring human pilot intervention |
| `ai-dlc/guidelines/entry-points.md` | Areas safe for autonomous AI work |
| `ai-dlc/rules/code-standards.md` | Extracted code standards with examples |

Files must be written even if the overall assessment is low-risk — they serve as the audit artifacts.

---

## No Confirmation Gate

In generic mode there is no issue to post back to, so all phases run fully autonomously without any pause. The work classification (Phase 2) is written directly to `ai-dlc/code-archaeology-analysis.md` without a comment-based review step.

---

## Output

On completion:

```
Code archaeology analysis complete: <N> modules — <N> Enhancement | <N> Remediation | <N> Migration — report: ai-dlc/code-archaeology-analysis.md
```

---

## When to Use

This provider is the correct fallback for:

- Self-hosted GitLab or Bitbucket instances
- Local or offline runs where no remote API is available
- CI environments where only the report file output is needed
- Running archaeology against a checked-out repository without a platform issue
