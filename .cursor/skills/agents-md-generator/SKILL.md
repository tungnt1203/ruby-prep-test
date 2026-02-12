---
name: agents-md-generator
description: "This skill should be used when the user asks to generate AGENTS.md files, create AI agent conventions, set up agent guides for a codebase, or update existing AGENTS.md files. Automates codebase analysis and produces a hierarchical system of AGENTS.md files that help AI coding agents follow project conventions."
version: 1.0.0
author: Minh Tang
created: 2026-02-08
updated: 2026-02-08
platforms: [cursor, claude-code, codex]
category: meta
tags: [agents, conventions, coding-standards, automation, scaffolding]
risk: safe
---

# agents-md-generator

## Purpose

Analyze any codebase (frontend, backend, or fullstack) and generate a hierarchical system of AGENTS.md files. These files serve as in-place convention guides that AI coding agents automatically discover when working in each directory. The root AGENTS.md acts as a coordinator with a decision tree, while module-level AGENTS.md files contain specific rules, patterns, and anti-patterns.

## When to Use This Skill

- User asks to generate AGENTS.md for a project
- User asks to create coding conventions for AI agents
- User wants to update existing AGENTS.md after adding new modules
- User mentions "agents md", "generate agents", "create agents", "setup agents", "update agents"

## Operating Modes

Detect mode from user prompt:

- **generate** (default): Full codebase analysis → create all AGENTS.md files from scratch
- **update**: Scan for new/changed modules → create or update only affected AGENTS.md files

### When to Use Each Mode

| Situation | Mode |
|-----------|------|
| First time setting up AGENTS.md | `generate` |
| Major project restructure or refactor | `generate` |
| Added new module/directory | `update` |
| Renamed or moved directories | `update` |
| Convention rules changed | `update` |
| Minor rule tweak in one file | Manual edit (no skill needed) |

---

## Workflow Overview

Before generating any AGENTS.md, you MUST understand the project. Follow this sequence strictly:

```
1. EXPLORE   → Understand what this project is (stack, structure, patterns)
2. DISCOVER  → Find existing conventions and analyze code
3. CONFIRM   → Show findings to user, get approval
4. GENERATE  → Create root AGENTS.md → confirm → create module files one by one
5. VALIDATE  → Spot-check consistency, deprecate old files
```

**Critical: You are starting with ZERO knowledge of this project.** Do not assume anything. Do not skip exploration. Every rule you write must be backed by evidence from the codebase.

### Behavioral Mandate

These principles govern your behavior throughout the entire workflow:

1. **Zero-Fabrication** — Never invent rules, patterns, or conventions. If you cannot detect a clear pattern from the code, say so. Writing a wrong rule is worse than writing no rule.
2. **Grounded in Code** — Every claim in AGENTS.md must trace back to actual files you read. Do not theorize about what the codebase "probably" does.
3. **Don't Fake Understanding** — If a module's purpose or pattern is unclear after analysis, flag it to the user: "I could not determine a clear convention for {module}. Please clarify or skip."
4. **Critique, Don't Ignore** — If actual code violates its own stated conventions (e.g., convention says `*Page.vue` but files exist without this suffix), flag the inconsistency. Do not silently pick one side.
5. **Curiosity Over Speed** — When something looks unusual or inconsistent, investigate deeper (read more files, check sub-directories) before concluding. Don't rush to generate.

### Exploration Checklist (Mandatory First Actions)

Before Phase 1 begins, perform these actions in order:

1. **Read project root** — list all files and directories at the project root
2. **Identify entry points** — read `package.json`, `Gemfile`, `go.mod`, `pyproject.toml`, or equivalent to understand the tech stack, dependencies, and scripts
3. **Read build/config files** — check framework config files (e.g., `vite.config.*`, `next.config.*`, `quasar.config.*`, `webpack.config.*`, `tsconfig.json`, `Rakefile`, etc.)
4. **Map source directory** — list the main source directory (`src/`, `app/`, `lib/`) to depth 2
5. **Read README** — if exists, read `README.md` for project overview
6. **Search for existing rules** — search for convention, style guide, contributing, or agent files (patterns listed in Phase 1.3)

Only after completing this checklist should you proceed to Phase 1.

---

## Phase 1: Discovery (Both Modes)

### 1.1 Detect Tech Stack

Scan project root for dependency/config files:

| File | Indicates |
|------|-----------|
| `package.json` | Node.js / Frontend (check for React, Vue, Next.js, Nuxt, Angular, Svelte, Quasar...) |
| `Gemfile` | Ruby / Rails |
| `requirements.txt` / `pyproject.toml` | Python (Django, FastAPI, Flask...) |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `composer.json` | PHP / Laravel |
| `*.csproj` / `*.sln` | .NET / C# |

Extract: framework, language, build tools, testing framework, state management, CSS framework.

### 1.2 Map Source Structure

Identify the main source directory (commonly `src/`, `app/`, `lib/`, or project root).

List all first-level directories inside the source directory. Each directory is a "module" that receives its own AGENTS.md.

### 1.3 Find Existing Conventions

Search the project for convention or guide files:

```
**/convention*.md
**/CONVENTION*.md
**/CODING_STANDARD*.md
**/STYLE_GUIDE*.md
**/CONTRIBUTING.md
**/docs/rules/**
**/docs/guides/**
**/.cursorrules
**/.cursor/rules/**
**/AGENTS.md
```

Read all found files. Their content will be absorbed, upgraded, and distributed into the AGENTS.md system.

### 1.4 Analyze Code Patterns

For each source directory, sample files based on module size:

| Module Size | Sample Count |
|-------------|-------------|
| Small (<20 files) | 3-5 files |
| Medium (20-100 files) | 5-10 files |
| Large (>100 files) | 10-15 files across sub-directories |

**Sampling heuristic** — select files by:
1. Most recently modified files (reflect current conventions)
2. Ensure coverage across all sub-directories
3. Prefer files with typical naming patterns (avoid test/mock/generated files)

**Display the list of sampled files to the user before extracting patterns.**

From sampled files, extract:

- File naming patterns (suffix, prefix, casing)
- Function/variable naming patterns
- Import/export conventions
- Directory nesting conventions
- Common patterns and anti-patterns observed

### 1.5 Resolve Convention vs Code Conflicts

When existing convention documents (from 1.3) conflict with actual code patterns (from 1.4):

1. Flag each conflict explicitly to the user
2. Ask which to prioritize: existing convention (aspirational) or actual code (current reality)
3. Default: **actual code wins** — convention is noted as aspirational if user does not respond
4. If no consistent pattern is detected for a module, flag to user: "No clear convention found for {module}. Skip or define new convention?" — **do NOT fabricate rules**

### 1.6 Discovery Output

Display a summary to the user for confirmation:

```
Project Type: [frontend / backend / fullstack]
Stack: [detected tech stack]
Source Root: [path]
Modules Found: [list of directories]
Existing Conventions: [list of files found and absorbed]
```

Ask: "Does this look correct? Any modules to exclude or add?"

**STOP. Wait for user confirmation before proceeding.**

---

## Phase 2: Generate Root AGENTS.md

Create `PROJECT_ROOT/AGENTS.md` using the Root Template below.

### Root Template

```markdown
# AGENTS.md

<!-- generated by agents-md-generator | last_generated: {YYYY-MM-DD} -->

> AI Agent Guide — Entry point for AI coding agents working in this project.

## Project Overview

| Aspect | Value |
|--------|-------|
| **Stack** | {detected stack summary} |
| **Architecture** | {detected architecture pattern} |
| **Source Root** | `{source directory path}` |

## Global Rules

### Naming Conventions

{extracted naming rules — file, function, variable naming}

### Coding Style

{top 5-7 most important coding style rules}

### Import Rules

{cross-module import constraints, if applicable}

## Module Map

| Directory | Purpose | Complexity |
|-----------|---------|------------|
| `{dir}/` | {one-line purpose} | {simple / moderate / complex} |

## Decision Tree

When you receive a task, determine which module(s) are involved and read their AGENTS.md:

| Task Type | Read |
|-----------|------|
| {task category} | `{path}/AGENTS.md` |

## Before Any Task

1. Read this file (you are doing it now)
2. Identify which module(s) your task touches
3. Read the AGENTS.md in each relevant module directory
4. Follow both global rules (this file) AND module-specific rules

## Common Pitfalls

| ❌ Don't | ✅ Do |
|----------|-------|
| {common mistake} | {correct approach} |
```

### Root File Rules

- Target ~80-100 lines maximum
- Only rules that apply project-wide — no module-specific rules
- Decision Tree must cover all common task types
- Common Pitfalls limited to top 5-7 most frequent mistakes
- Use real examples from the codebase, not hypothetical ones

### Confirmation Gate

After generating root AGENTS.md, **display the full content to the user**.

Ask: "Review the root AGENTS.md above. Confirm before generating module files?"

**STOP. Wait for user confirmation before proceeding to Phase 3.**

---

## Phase 3: Generate Module AGENTS.md Files

For each source directory identified in Phase 1, create `{source_dir}/{module}/AGENTS.md`.

### 3.1 Classify Module Complexity

Before generating, classify each module:

| Complexity | Criteria | Target Length |
|------------|----------|---------------|
| **Simple** | Constants, types, i18n, config — mostly declarations | 50-80 lines |
| **Moderate** | Helpers, hooks, utils — reusable logic, clear patterns | 80-120 lines |
| **Complex** | Components, pages, modules, stores, routes — business logic, state, UI | 120-200 lines |

### 3.2 Module Template

All module AGENTS.md files follow this common template. Sections marked **[moderate+]** appear only for moderate and complex modules. Sections marked **[complex only]** appear only for complex modules.

```markdown
# AGENTS.md — {Module Name}

<!-- generated by agents-md-generator | last_generated: {YYYY-MM-DD} -->

> {One-line purpose of this module}

## Structure

{Actual directory tree of this module, 2 levels deep}

## Naming Conventions

| Element | Pattern | Example |
|---------|---------|---------|
| {file / function / variable / component} | {naming pattern} | {real example from codebase} |

## Rules

### Do

- {imperative rule}
- {imperative rule}

### Don't

- {anti-rule}
- {anti-rule}

## Dependencies [moderate+]

### Allowed Imports From

- `{module}` — {why}

### Must NOT Import From

- `{module}` — {why}

## Patterns [complex only]

### ✅ Good

```{lang}
{real good code example from codebase}
```

### ❌ Bad

```{lang}
{real bad code example — what to avoid and why}
```

## Related Files

| File | Relationship |
|------|-------------|
| `PROJECT_ROOT/AGENTS.md` | Global rules and decision tree — read first |
| `{sibling_module}/AGENTS.md` | {why this module commonly interacts with it} |

## Checklist — New File [complex only]

Before creating a new file in this module:

- [ ] {verification step}
- [ ] {verification step}
- [ ] {verification step}
```

### Module File Rules

- Use actual code from the codebase in examples, not hypothetical code
- Naming convention examples must reflect real files that exist
- If a module has sub-directories with distinct patterns, document each
- Do NOT repeat global rules from root AGENTS.md — reference them instead
- Keep language imperative and direct — no explanatory prose
- Anti-patterns in [complex only] sections must include a brief "why" explanation
- **Hard limit**: If a module AGENTS.md exceeds 200 lines, split content or remove less critical sections. Flag to user if unable to fit within limit.

### Related Files Rules

Every module AGENTS.md MUST include a **Related Files** section. This ensures the agent can navigate the AGENTS.md system even if it has not read the root file.

Rules for populating Related Files:

1. **Always include** `PROJECT_ROOT/AGENTS.md` as the first entry — it contains global rules
2. **List sibling modules** that this module commonly imports from or exports to (based on actual import analysis in Phase 1.4)
3. **Describe the relationship** concisely — e.g., "Components in this module consume hooks defined here", "Stores used by pages in this module"
4. **Keep the list short** — maximum 5 related files. Only the most frequently linked modules.
5. **Use relative paths** from project root for consistency

### Sequential Processing (Critical)

Process modules **one at a time**:

1. Analyze module → write its AGENTS.md → move to next module
2. Do NOT hold multiple modules in context simultaneously
3. After writing each file, confirm to user: "Created {path}/AGENTS.md ({N} lines)"

---

## Phase 4: Cleanup & Validation

### 4.1 Deprecate Old Convention Files

For each existing convention file found in Phase 1, add a deprecation header:

```markdown
> ⚠️ DEPRECATED — This file has been replaced by the AGENTS.md system.
> See PROJECT_ROOT/AGENTS.md for the entry point.
```

Do NOT delete the file. Let the user decide when to remove it.

### 4.2 Validate Consistency

Spot-check (do NOT re-read all files at once):

- Verify root Module Map lists all modules that received AGENTS.md files
- Verify root Decision Tree covers task types for all modules
- Spot-check 2-3 module files: ensure no global rule is duplicated
- Confirm no business logic, API docs, or deployment instructions leaked in

### 4.3 Final Summary

Display completion summary:

```
✅ AGENTS.md Generation Complete

Files created:
  - PROJECT_ROOT/AGENTS.md (root coordinator)
  - {list each module AGENTS.md with line count}

Files deprecated:
  - {list old convention files with deprecation header added}

Total: {N} AGENTS.md files covering {M} modules

Next steps:
  1. Review each generated AGENTS.md file
  2. Remove deprecated convention files when ready
  3. Use "update" mode when adding new modules
```

---

## Update Mode Workflow

When invoked with `update` intent:

### Step 1: Re-discover

Run Phase 1 (Discovery) — build the current state of the codebase.

### Step 2: Detect Changes

Compare current codebase state against existing AGENTS.md files. Check for ALL of the following:

| Change Type | How to Detect | Label |
|-------------|---------------|-------|
| **New module** | Directory exists, no AGENTS.md inside | `[NEW]` |
| **New sub-directories** | AGENTS.md `## Structure` section missing directories that now exist | `[UPDATE]` |
| **New file patterns** | Naming patterns in code not documented in AGENTS.md `## Naming Conventions` | `[UPDATE]` |
| **Outdated Related Files** | Module references sibling that no longer exists, or misses new frequently-linked sibling | `[UPDATE]` |
| **Stale root Module Map** | Root AGENTS.md `## Module Map` missing new modules or listing deleted ones | `[UPDATE-ROOT]` |
| **Stale root Decision Tree** | Root AGENTS.md `## Decision Tree` missing task types for new modules | `[UPDATE-ROOT]` |
| **New convention files** | Convention/guide files found that were not absorbed in previous run | `[ABSORB]` |
| **Deleted module** | AGENTS.md exists but directory has been removed | `[REMOVE]` |
| **Timestamp check** | Compare `last_generated` timestamp with most recent file modification in module — if files modified significantly after generation, flag for review | `[REVIEW]` |

### Step 3: Display Diff Summary

```
Changes detected:
  [NEW]         src/notifications/       — no AGENTS.md found
  [UPDATE]      src/components/          — 3 new sub-directories not documented
  [UPDATE]      src/hooks/               — 2 new naming patterns detected (useDialog, useModal)
  [UPDATE-ROOT] AGENTS.md                — Module Map missing src/notifications/
  [REVIEW]      src/stores/              — 15 files modified since last generation
  [REMOVE]      src/legacy/              — directory no longer exists
```

### Step 4: User Confirmation

Ask user to confirm which changes to apply. User may:
- Accept all
- Accept selectively
- Skip specific items
- Provide additional context for unclear items

### Step 5: Execute

Apply confirmed changes only:
- `[NEW]` → Run full Phase 3 for that module
- `[UPDATE]` → Re-read module, regenerate AGENTS.md (preserve any manual edits user has flagged)
- `[UPDATE-ROOT]` → Regenerate only the affected sections of root AGENTS.md
- `[ABSORB]` → Read new convention file, distribute relevant content
- `[REMOVE]` → Delete orphaned AGENTS.md (ask user first)
- `[REVIEW]` → Re-analyze module, show diff of proposed changes vs current AGENTS.md

### Step 6: Validate

Run Phase 4.2 spot-check on changed files only.

---

## Key Principles

- **Generic** — No project names, no business logic, no domain knowledge in output
- **Evidence-based** — All rules derived from actual code analysis, not assumptions
- **Incremental** — Validate each phase before proceeding to the next
- **Consistent** — All module files follow the common template structure
- **Proportional** — Detail level matches module complexity
- **Agent-first** — Written for AI consumption: imperative, structured, scannable
- **Non-destructive** — Never delete existing files; deprecate and let user decide
- **Human-approved** — All changes displayed and confirmed before writing
