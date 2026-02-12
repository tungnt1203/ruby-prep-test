---
name: skill-scaffolder
description: "Generate project-level Cursor skills (reviewer, implement-feature, pr-description) for any frontend/backend/fullstack project. Analyzes codebase or reuses AGENTS.md files, fills templates with project-specific patterns, and writes ready-to-use SKILL.md files. Use when setting up a new project, onboarding AI agents, or creating workflow skills."
version: 1.1.0
author: Minh Tang
created: 2026-02-08
updated: 2026-02-08
platforms: [cursor, claude-code]
category: meta
tags: [scaffolding, skills, setup, project, workflow, review, pr]
risk: safe
---

# skill-scaffolder

## Purpose

Generate project-level workflow skills for any codebase. Instead of manually writing and hardcoding framework-specific patterns into each skill, this meta-skill analyzes the project (or reuses existing AGENTS.md files) and produces ready-to-use skills tailored to the detected stack, module structure, and conventions.

## When to Use

- Setting up a new project with Cursor/Claude Code
- User says "scaffold skills", "create project skills", "setup skills", "generate reviewer/implement/pr skills"
- After running `agents-md-generator` and wanting workflow skills that reference those conventions
- When onboarding a project that has no existing Cursor skills

---

## Folder Structure

This skill uses a **template-based architecture** with templates in separate folders:

```
.cursor/skills/skill-scaffolder/
├── SKILL.md                                   # This file — orchestration logic
├── templates/
│   ├── reviewer/
│   │   ├── SKILL.template.md                  # Template with {{PLACEHOLDER}} markers
│   │   └── RESOLUTION.md                      # How to fill each placeholder
│   ├── implement-feature/
│   │   ├── SKILL.template.md
│   │   └── RESOLUTION.md
│   └── pr-description/
│       ├── SKILL.template.md
│       └── RESOLUTION.md
```

**Adding a new skill template:** Create a new folder under `templates/` with `SKILL.template.md` + `RESOLUTION.md`, then add an entry to the Skill Catalog (Phase 2).

---

## Behavioral Mandate

1. **Zero-Fabrication** — Never invent conventions, patterns, or rules. Every check, rule, or pattern in a generated skill must trace back to actual code or AGENTS.md content you read.
2. **Grounded in Code** — If you cannot detect a clear pattern, say so. Writing a wrong rule is worse than writing no rule.
3. **Human-Approved** — Display every generated skill to the user before writing. Never write files without explicit confirmation.
4. **Sequential Processing** — Generate one skill at a time. Read only the template you need, fill it, confirm, write, then move to the next. Do NOT hold multiple templates in context simultaneously.
5. **No Hardcoded Project Names** — Generated skills use "this project", "the codebase" — never specific repo or project names.

---

## Workflow Overview

```
1. DETECT    → Understand the project (stack, modules, conventions)
2. SELECT    → User chooses which skills to generate
3. GENERATE  → Read template → fill → preview → confirm → write (one at a time)
4. VALIDATE  → Check completeness and consistency
5. SUMMARIZE → Show what was created
```

---

## Phase 1: Codebase Detection

### 1.1 Tier 1 — Reuse Existing AGENTS.md

Check for AGENTS.md files first. This is the fastest and most reliable path.

1. Search for `PROJECT_ROOT/AGENTS.md`
2. If found, read it and extract:
   - **Stack** from `## Project Overview` table
   - **Modules** from `## Module Map` table
   - **Global rules** from `## Global Rules` section (naming, coding style, imports)
   - **Decision tree** from `## Decision Tree`
3. Search for `{source_dir}/{module}/AGENTS.md` files
4. For each found, extract:
   - Module purpose (first line after heading)
   - Naming conventions table
   - Do/Don't rules
   - Dependency/import rules
   - Related files

If root AGENTS.md is found → skip Tier 2 for global context.
If module AGENTS.md files are found → skip Tier 2 sampling for those modules.

### 1.2 Tier 2 — Lightweight Independent Analysis

When no AGENTS.md files exist, perform focused analysis:

**Step 1: Detect tech stack**

| File | Indicates |
|------|-----------|
| `package.json` | Node.js / Frontend (check dependencies for React, Vue, Next.js, Nuxt, Angular, Svelte, Quasar...) |
| `Gemfile` | Ruby / Rails |
| `requirements.txt` / `pyproject.toml` | Python (Django, FastAPI, Flask...) |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `composer.json` | PHP / Laravel |
| `*.csproj` / `*.sln` | .NET / C# |

Read the dependency file to extract: framework, language, UI library, state management, CSS framework, testing framework.

**Step 2: Map source structure**

List the main source directory (`src/`, `app/`, `lib/`, or project root) to depth 2. Each first-level directory is a "module".

**Step 3: Sample code patterns**

For each module, read 3-5 files (prefer recently modified, typical naming). Extract:
- File naming patterns (suffix, prefix, casing)
- Import/export conventions
- Common code structures (component patterns, API patterns, etc.)

### 1.3 Tier 3 — User Input Fallback

For any aspect that remains ambiguous after Tier 1 and Tier 2:

- If multiple stacks detected → ask user to confirm the primary stack
- If module purpose is unclear → ask user or skip that module
- If no clear naming convention found → flag to user: "No clear convention detected for {module}. I'll use generic rules."

### 1.4 Convention File Search

Regardless of tier, search for and read these if they exist:

```
**/convention*.md
**/CONVENTION*.md
**/CONTRIBUTING.md
**/STYLE_GUIDE*.md
**/.cursorrules
**/.cursor/rules/**
**/docs/rules/**
**/docs/guides/**
```

Incorporate relevant content into the detected context. If conventions conflict with actual code patterns, default to actual code (note the conflict to user).

### 1.5 Context Summary & Confirmation Gate

Display a summary to the user:

```
Detected Project Context:

  Project Type:     {frontend / backend / fullstack}
  Tech Stack:       {framework, language, key libraries}
  Source Root:       {path}
  Modules Found:    {list with one-line purposes}
  Context Source:    {AGENTS.md / independent analysis / mixed}
  PR Template:      {path or "not found"}
  Unclear Aspects:  {list or "none"}

Does this look correct? Any corrections?
```

**STOP. Wait for user confirmation before proceeding to Phase 2.**

---

## Phase 2: Skill Selection

### 2.1 Skill Catalog

| ID | Template Path | Description | Category |
|----|--------------|-------------|----------|
| `reviewer` | `templates/reviewer/` | Review code for bugs, security, performance, edge cases, best practices, and convention compliance | review |
| `implement-feature` | `templates/implement-feature/` | Step-by-step workflow for implementing features with convention adherence | workflow |
| `pr-description` | `templates/pr-description/` | Generate PR description by analyzing git changes and filling the project's PR template | git |

### 2.2 Catalog Presentation

**If user specifies skills in prompt** (e.g., "create reviewer and pr-description"):
→ Map to catalog entries, confirm selection, proceed.

**If user does not specify**:
→ Display the catalog table above with recommendations (see 2.3), ask user to select.

**If user says "all"**:
→ Queue all skills in order: reviewer → implement-feature → pr-description.

### 2.3 Project-Type Recommendations

| Project Type | Recommended | Emphasis |
|--------------|-------------|----------|
| Frontend | All three | UI/component patterns in reviewer and implement-feature |
| Backend | All three | API patterns, DB operations, security in reviewer |
| Fullstack | All three | Both frontend and backend patterns distributed across skills |

Present recommendations but accept any user selection without objection.

---

## Phase 3: Generate Skills

### 3.1 Sequential Generation

For each selected skill, in order:

1. **Read** the template: `templates/{skill-id}/SKILL.template.md`
2. **Read** the resolution rules: `templates/{skill-id}/RESOLUTION.md`
3. **Fill** each placeholder using the detected codebase context and resolution rules
4. For **contextual placeholders** (review checks, implementation patterns): generate project-specific content based on the detected stack and patterns — do NOT use generic filler
5. **Validate** (Phase 4 checks)
6. **Display** the complete generated SKILL.md to user
7. **Wait** for confirmation → write file → proceed to next skill

**Important: After completing one skill, release its template from context before loading the next.** This prevents context window overflow.

### 3.2 User Confirmation Gate

After filling a template, display:

```
Generated: {skill-name}/SKILL.md ({N} lines)

{full content of the generated SKILL.md}

---
Confirm to write this file? (yes / modify / skip)
```

- **yes** → write the file
- **modify** → user describes changes, agent applies and re-shows
- **skip** → skip this skill, move to next

### 3.3 File Output

Write confirmed skills to: `{project_root}/.cursor/skills/{skill-name}/SKILL.md`

Create the directory if it doesn't exist. Do NOT overwrite existing files without asking the user first.

---

## Phase 4: Validation

### 4.1 Completeness Check

Before showing a generated skill to user, verify:

- [ ] YAML frontmatter has all required fields (name, description, version, created, platforms, category, tags, risk)
- [ ] Contains `## Purpose` section
- [ ] Contains `## When to Use` section
- [ ] Contains at least one workflow step or process section
- [ ] Contains `## Principles` section
- [ ] No remaining `{{PLACEHOLDER}}` markers in the output
- [ ] Under 300 lines (recommended max for generated skills)

### 4.2 Cross-Skill Consistency

After generating multiple skills for the same project:

- Module names and directory paths referenced in reviewer must match those in implement-feature
- Naming conventions in reviewer checks must match implement-feature coding rules
- implement-feature "Next steps" section must reference the actual generated skill names (reviewer, pr-description)
- pr-description skill section must list all generated skills

### 4.3 AGENTS.md Consistency

If AGENTS.md files exist:

- Naming conventions in generated skills must match AGENTS.md conventions
- Import restrictions in implement-feature must match AGENTS.md dependency rules
- Flag any discrepancy to user before writing

### 4.4 Generation Summary

After all skills are generated (or skipped), display:

```
Skill Scaffolding Complete

  Files created:
    - .cursor/skills/reviewer/SKILL.md ({N} lines)
    - .cursor/skills/implement-feature/SKILL.md ({N} lines)
    - .cursor/skills/pr-description/SKILL.md ({N} lines)

  Context source: {AGENTS.md / independent analysis}

  Skipped: {list or "none"}
  Failed:  {list or "none"}

  Next steps:
    1. Review each generated skill
    2. Run @agents-md-generator if AGENTS.md files don't exist yet
    3. Use the skills: @reviewer, @implement-feature, @pr-description
```

---

## Key Principles

- **Generic** — No project names or business domain terms in generated output structure
- **Evidence-based** — All rules and patterns derived from actual code or AGENTS.md, not assumptions
- **Human-approved** — Every generated file displayed and confirmed before writing
- **Sequential** — One skill at a time to manage context window
- **Extensible** — New templates can be added by creating a new folder under `templates/` with `SKILL.template.md` + `RESOLUTION.md`, and adding an entry to the catalog table
- **Non-destructive** — Never overwrite existing files without asking
- **Quality over speed** — A well-crafted skill saves hours of future correction; take time to get it right
