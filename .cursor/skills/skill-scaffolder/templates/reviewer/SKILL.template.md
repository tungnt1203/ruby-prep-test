---
name: reviewer
description: "{{DESCRIPTION}}"
version: 1.0.0
created: {{DATE}}
platforms: [cursor, claude-code]
category: code-review
tags: [review, security, performance, conventions, quality]
risk: safe
---

# reviewer

## Purpose

Review code changes across six dimensions: correctness, security, performance, edge cases, best practices, and project convention compliance. Produce actionable findings grouped by severity.

## When to Use

- After implementing a feature or fix
- Before committing or creating a PR
- User says "review", "check code", "review changes"
- When reviewing code written by another agent or developer

---

## Step 1: Identify Changed Files

Determine scope by priority:

1. **User specifies files/directories** — use exactly what they provide
2. **Staged + unstaged changes** — `git diff --name-only` and `git diff --name-only --cached`
3. **Recent commits on current branch** — `git log --oneline -10` then `git diff --name-only {commit}..HEAD`

Group changed files by module ({{MODULE_GROUPING}}).

---

## Step 2: Load Context

1. Read `AGENTS.md` at project root (if exists)
2. Read `{{SOURCE_DIR}}/{module}/AGENTS.md` for each module with changed files
3. Scan surrounding files in the same directory to understand existing patterns

---

## Step 3: Review Each File

### 3.1 — Correctness & Bugs

{{CORRECTNESS_CHECKS}}

### 3.2 — Security

{{SECURITY_CHECKS}}

### 3.3 — Performance

{{PERFORMANCE_CHECKS}}

### 3.4 — Edge Cases

{{EDGE_CASE_CHECKS}}

### 3.5 — Best Practices ({{TECH_STACK}})

{{BEST_PRACTICE_CHECKS}}

### 3.6 — Convention Compliance

{{CONVENTION_CHECKS}}

---

## Step 4: Report

Group findings by severity. Be direct — state the problem, state the fix.

```markdown
## Code Review Report

**Files reviewed:** {N}
**Modules:** {list}

---

### 🔴 BLOCKING ({N})

Issues that must be fixed — bugs, security risks, or hard convention violations.

**1. [{Category}] {Title}** — `{file}:{line}`
> {Description}
> **Fix:** {concrete fix}

---

### 🟡 IMPORTANT ({N})

Issues that should be fixed — performance, edge cases, best practice violations.

---

### 🟢 MINOR ({N})

Nice-to-fix — style, naming, minor improvements.

---

### ✅ CLEAN

Files that passed all checks: {list}
```

---

## Severity Definitions

| Severity | Meaning | Action |
|----------|---------|--------|
| 🔴 BLOCKING | Bug, security flaw, or MUST rule violation | Fix before merge |
| 🟡 IMPORTANT | Performance, edge case, SHOULD rule violation | Fix recommended |
| 🟢 MINOR | Style, naming, suggestion | Fix when convenient |

---

## Principles

- **Practical** — Every finding has a concrete fix, not just a complaint
- **Proportional** — Don't flag 20 minor issues when there are 2 blocking ones
- **Context-aware** — Check existing patterns before flagging as wrong
- **Honest** — If the code is clean, say so. Don't invent issues
- **Concise** — One-liner per finding when possible
