---
name: reviewer
description: "Review code for bugs, security, performance, edge cases, best practices, and convention compliance for Ruby on Rails projects."
version: 1.0.0
created: 2026-02-12
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

Group changed files by module (`src/app/controllers/`, `src/app/models/`, `src/app/services/`, `src/app/views/`, `src/app/frontend/`, `src/test/`).

---

## Step 2: Load Context

1. Read `AGENTS.md` at project root (if exists)
2. Read `src/app/{module}/AGENTS.md` for each module with changed files
3. Scan surrounding files in the same directory to understand existing patterns

---

## Step 3: Review Each File

### 3.1 — Correctness & Bugs

- ActiveRecord query returns nil/empty — check for `.first`, `.find_by` without nil handling
- Callback order issues — `before_save`, `after_create` side effects that depend on other attributes
- Transaction usage — operations that should be atomic but aren't wrapped in `transaction do`
- Association misuse — calling `.create!` on `has_many` without proper parent context
- Missing validations — model accepts invalid data that breaks downstream logic
- Service object `call` method — ensure it handles all error paths and returns consistent structure
- Controller redirect loops — check `redirect_to` conditions that may conflict

### 3.2 — Security

- Hardcoded secrets, API keys, or tokens in source files
- SQL injection via string interpolation in queries (use parameterized queries or `where(column: value)`)
- Mass assignment — `params.permit` missing required fields or permitting dangerous fields
- Missing CSRF token checks on non-GET requests
- User input rendered without sanitization (XSS in views)
- Missing authentication checks — actions accessible without `require_login` or similar
- Session data exposure — sensitive data stored in session without encryption

### 3.3 — Performance

- N+1 queries — missing `includes`, `preload`, or `eager_load` on associations
- Unbounded queries — `Model.all` or queries without `LIMIT` on large tables
- Missing database indexes — queries filtering on non-indexed columns
- Synchronous operations in request cycle that should be background jobs
- Repeated queries in loops — move outside loop or use batch loading
- View rendering N times for list items — use `render collection:` pattern
- Missing caching for expensive computations or repeated database reads

### 3.4 — Edge Cases

- What if `find_by` returns nil? Is there proper error handling?
- What if the collection is empty? Does the view handle zero-item state?
- What if the user submits the form twice (double-click)?
- What if session expires mid-operation?
- What if required associations are missing (orphan records)?
- What if input values are at boundaries (0, negative, max integer)?
- What if external service calls timeout or return errors?

### 3.5 — Best Practices (Ruby on Rails 8.1)

- Controllers: Keep actions thin — business logic belongs in models or services
- Models: Use scopes for reusable query patterns, validations for data integrity
- Services: Follow `call` method pattern, raise custom errors for failure cases
- Views: Use partials for repeated markup, helpers for complex logic
- Tests: One assertion concept per test, use fixtures for test data
- Avoid `rescue Exception` — use specific error classes
- Use `frozen_string_literal: true` pragma at top of all Ruby files

### 3.6 — Convention Compliance

- File placement: Controllers in `src/app/controllers/`, models in `src/app/models/`, services in `src/app/services/`
- Naming: `snake_case` for files and methods, `PascalCase` for classes
- Rubocop: Code must pass `bin/rubocop` (rubocop-rails-omakase style)
- Stimulus: Controllers use `_controller.js` suffix in `src/app/frontend/controllers/`
- Tests: Controller tests in `src/test/controllers/`, named `{controller}_test.rb`
- Branch naming: `feature/name` or `fix/name` for git branches

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
