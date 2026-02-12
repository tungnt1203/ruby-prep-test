---
name: pr-description
description: "Generate PR description by analyzing git changes and filling the project's PR template."
version: 1.0.0
created: 2026-02-12
platforms: [cursor, claude-code]
category: git
tags: [pr, pull-request, git, description]
risk: safe
---

# pr-description

## Purpose

Analyze git changes on the current branch and generate a PR description that fills the project's PR template. Adapts to whatever template structure exists.

## When to Use

- User says "create PR", "PR description", "write PR", "prepare PR"
- After changes are ready to push

---

## Process

### 1. Gather Changes

```bash
git branch --show-current
git log --oneline -20
git diff --name-only --cached
git diff --name-only
```

Read the actual diff content to understand what changed.

### 2. Read Template

Look for the PR template in this order:
1. `.github/PULL_REQUEST_TEMPLATE.md`
2. `.github/pull_request_template.md`
3. `docs/pull_request_template.md`

If no template exists, use a minimal format:
- **Ticket:** {ticket ID or "N/A"}
- **What Changed:** {summary of changes}
- **How to Test:** {testing steps}

### 3. Analyze & Think

- **What type of change?** Feature, bugfix, refactor, chore
- **Which modules/areas are affected?** Map changed files to project structure
- **What's the user-facing impact?**
- **What could break?** Shared code, cross-feature dependencies
- **Which environment/context to test?**

### 4. Fill Template

- Understand the intent of each section from its heading and comments
- Be concrete — use actual file names, routes, feature names from the diff
- Be concise — match the level of detail the template asks for
- Checkboxes — check what actually applies, don't blindly check all
- Placeholders — if information is unknown (e.g., ticket ID), leave placeholder and tell user

#### 4.1 — When the PR adds or changes Cursor skills

If the diff includes files under `.cursor/skills/`, add a **Cursor Skills** section to the PR description. For each skill added or changed:

1. **Summary** — one sentence: purpose + when to use
2. **Usage** — example prompt using `@skill-name`

| Skill | Summary | Example |
|-------|---------|---------|
| `reviewer` | Review code for bugs, security, performance, and conventions | `@reviewer check my changes` |
| `implement-feature` | Step-by-step workflow for implementing features with convention adherence | `@implement-feature add user profile page` |
| `pr-description` | Generate PR description from git changes | `@pr-description` |

### 5. Output

Present as a single markdown code block — ready to copy-paste.

---

## Principles

- **Template is the source of truth** — follow its structure, don't add or skip sections
- **Concise** — reviewer should understand the PR in 30 seconds
- **Honest** — small change = small description. Don't inflate
- **English by default** — unless user requests another language
