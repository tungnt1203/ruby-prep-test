---
name: implement-feature
description: "Step-by-step workflow for implementing features in Ruby on Rails projects with convention adherence."
version: 1.0.0
created: 2026-02-12
platforms: [cursor, claude-code]
category: workflow
tags: [implement, feature, coding, workflow, convention]
risk: safe
---

# implement-feature

## Purpose

Guide the implementation process from receiving a requirement to code completion. Ensures agent follows project conventions, clarifies before coding, stays within spec, and produces consistent output.

## When to Use

- User says "implement", "build", "create feature", "add page", "add endpoint"
- User provides a ticket or description of work to do
- Any task that results in new or modified code

---

## Phase 1: Parse Requirements

Read the input and extract:

- **What** needs to be built or changed
- **Which area** of the codebase (exam flow, rooms, user auth, dashboard)
- **Which modules** will be touched

Classify complexity:

| Complexity | Signals |
|------------|---------|
| **Simple** | 1 module, clear scope (fix bug, add field, tweak UI) |
| **Medium** | 2-3 modules, new logic but contained |
| **Complex** | 4+ modules, new feature, affects existing flows |

---

## Phase 2: Clarify (if needed)

**Simple** → Skip or 1 quick question. **Medium** → Confirm key decisions. **Complex** → Present summary and wait for confirmation:

```
I'll implement [feature]:
- Modules: ...
- Files to create/modify: ...
- Assumptions: ...
Should I proceed?
```

**Hard rules:**
- Ambiguous → ask, don't guess
- Multiple valid approaches → present options
- Never implement functionality not in the requirement
- Never add unrequested features

---

## Phase 3: Plan

### 3.1 — Module Mapping

| Need | Module |
|------|--------|
| API endpoint / page entry | `src/app/controllers/` |
| Business logic | `src/app/services/` |
| Data access / domain logic | `src/app/models/` |
| HTML rendering | `src/app/views/` |
| View helpers | `src/app/helpers/` |
| Background job | `src/app/jobs/` |
| Email sending | `src/app/mailers/` |
| Frontend interactivity | `src/app/frontend/controllers/` (Stimulus) |
| Database changes | `src/db/migrate/` |
| Routes | `src/config/routes.rb` |
| Tests | `src/test/` |

### 3.2 — Check Existing Patterns

For each module to be touched:
1. Look at existing files in the same directory
2. Follow the same file naming, structure, and code patterns
3. If uncertain, read the module's `AGENTS.md` (if exists)

### 3.3 — Implementation Order

1. **Database** — migrations for schema changes
2. **Models** — ActiveRecord models, validations, associations
3. **Services** — business logic in service objects
4. **Controllers** — actions, strong parameters, redirects
5. **Views** — ERB templates, partials
6. **Routes** — add routes in `config/routes.rb`
7. **Frontend** — Stimulus controllers for JS behavior
8. **Tests** — controller/integration tests

---

## Phase 4: Implement

### DO:

- Add `# frozen_string_literal: true` at top of all Ruby files
- Follow existing patterns in the same directory — copy structure from sibling files
- Use strong parameters in controllers (`params.require(:model).permit(...)`)
- Keep controllers thin — move business logic to services or models
- Use service objects with `call` method for complex operations
- Handle nil/empty cases in queries (`.find_by` can return nil)
- Add validations in models for data integrity
- Use `transaction do` for operations that must be atomic

### DO NOT:

- Don't add features not in the requirement
- Don't refactor unrelated code while implementing
- Don't skip validations or error handling
- Don't use raw SQL with string interpolation (SQL injection risk)
- Don't put business logic in controllers
- Don't create new patterns when existing ones cover the case
- Don't hardcode secrets or configuration values

### While coding each file:

1. Check if a similar file exists nearby → mirror its structure
2. Apply correct naming convention (`snake_case.rb`)
3. Place in the correct directory
4. Run `bin/rubocop` to check style compliance

---

## Phase 5: Wrap Up

### Self-check:

- [ ] All files placed in correct module and directory
- [ ] Naming follows `snake_case` convention for files
- [ ] `frozen_string_literal: true` pragma in all Ruby files
- [ ] Only implemented what was requested — nothing extra
- [ ] Controllers use strong parameters
- [ ] Models have appropriate validations
- [ ] Migrations are reversible or have proper `down` method
- [ ] Tests added for new controller actions

### Summary:

```
Done. Here's what I implemented:

Created:
- {list of new files}

Modified:
- {list of modified files}

No changes outside the requested scope.
```

### Next steps:

```
- Review code → use @reviewer
- Create PR → use @pr-description
```

---

## Principles

- **Spec is the boundary** — implement exactly what's asked, nothing more
- **Ask before guessing** — ambiguity is resolved by asking, not assuming
- **Follow existing patterns** — the best convention is what's already in the codebase
- **Proportional effort** — simple task = fast process, complex task = thorough process
- **Transparent** — always tell user what you did and what you didn't do
