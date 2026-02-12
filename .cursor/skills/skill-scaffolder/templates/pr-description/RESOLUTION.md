# PR-Description — Placeholder Resolution Rules

How to fill each `{{PLACEHOLDER}}` in the pr-description template using detected codebase context.

## Simple Substitutions

| Placeholder | Resolution |
|-------------|------------|
| `{{DESCRIPTION}}` | "Generate PR description by analyzing git changes and filling the project's PR template." |
| `{{DATE}}` | Current date in YYYY-MM-DD format |
| `{{PR_TEMPLATE_PATH}}` | Detected path (e.g., `.github/pull_request_template.md`). If not found, use `.github/pull_request_template.md` as default search path. |

## Conditional Sections

### `{{PR_TEMPLATE_FALLBACK}}`

**If PR template found:** Remove this placeholder entirely (no extra text needed).

**If NO PR template found:** Replace with:
```
If no template exists, use a minimal format:
- **Ticket:** {ticket ID or "N/A"}
- **What Changed:** {summary of changes}
- **How to Test:** {testing steps}
```

### `{{SKILL_SECTION_HANDLING}}`

Generate a subsection for handling PRs that include Cursor skill changes:

```markdown
#### 4.1 — When the PR adds or changes Cursor skills

If the diff includes files under `.cursor/skills/`, add a **Cursor Skills** section to the PR description. For each skill added or changed:

1. **Summary** — one sentence: purpose + when to use
2. **Usage** — example prompt using `@skill-name`

| Skill | Summary | Example |
|-------|---------|---------|
| `{name}` | {purpose} | `{example prompt}` |
```

**Populate the table with the actual skill names generated in this scaffolding session.** If no other skills were generated alongside this one, include a generic instruction to list any skills found in the diff.
