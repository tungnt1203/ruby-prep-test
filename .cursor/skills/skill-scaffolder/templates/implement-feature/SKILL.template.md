---
name: implement-feature
description: "{{DESCRIPTION}}"
version: 1.0.0
created: {{DATE}}
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
- **Which context** ({{SITE_CONTEXTS}})
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

{{MODULE_MAPPING_TABLE}}

### 3.2 — Check Existing Patterns

For each module to be touched:
1. Look at existing files in the same directory
2. Follow the same file naming, structure, and code patterns
3. If uncertain, read the module's `AGENTS.md` (if exists)

### 3.3 — Implementation Order

{{IMPLEMENTATION_ORDER}}

---

## Phase 4: Implement

### DO:

{{CODING_DO_RULES}}

### DO NOT:

{{CODING_DONT_RULES}}

### While coding each file:

1. Check if a similar file exists nearby → mirror its structure
2. Apply correct naming convention
3. Place in the correct directory
4. Use barrel exports (`index.*`) if the directory uses them

---

## Phase 5: Wrap Up

### Self-check:

{{SELF_CHECK_LIST}}

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
