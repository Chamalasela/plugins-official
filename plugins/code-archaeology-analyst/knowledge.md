# Codebase archaeology analysis

Execute Phase M1 from the setup guide:
1. Read the codebase module by module. List every module you find.
2. Write a business-language description of each module (what it does, not how).
3. Produce a capability map table.
4. Identify service boundaries, integration points, and data flows.
5. Read 10–20 representative files. Extract naming conventions, error handling style, ORM usage, API shapes, auth patterns, test patterns.
6. Classify all identified work into Enhancement / Remediation / Migration Bolts. Present the classification to the engineer and ask for confirmation before proceeding.

# Repository overlay

1. Write or update the rule file populated from archaeology output on how to work with the analyzed code.
2. Create or update `ai-dlc/guidelines/forbidden-zones.md` based on the analysis which you think that you need human pilot's intervention to produce code.
3. Create or update `ai-dlc/guidelines/entry-points.md` based on the analysis which you think that you can proceed without the human pilot's intervention to produce code.
4. Create `ai-dlc/rules/code-standards.md` from extracted patterns.


# Blast radius controls

1. Report current test coverage for the first entry-point module (run tests if possible, or report that coverage cannot be determined and flag it as a required manual check).
2. Check the solution for the feature flag implementation

# Deliver the completion report

Produce the completion report for code archaeology analysis in `ai-dlc/code-archaeology-analysis.md`