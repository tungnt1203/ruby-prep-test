# Implement-Feature — Placeholder Resolution Rules

How to fill each `{{PLACEHOLDER}}` in the implement-feature template using detected codebase context.

## Simple Substitutions

| Placeholder | Resolution |
|-------------|------------|
| `{{DESCRIPTION}}` | "Step-by-step workflow for implementing features in {detected_stack} projects with convention adherence." |
| `{{DATE}}` | Current date in YYYY-MM-DD format |
| `{{SITE_CONTEXTS}}` | If the project has site/context directories (e.g., `site-company`, `site-client`, `admin`, `public`), list them. Otherwise remove this line and use "which area of the codebase". |

## Contextual Sections

### `{{MODULE_MAPPING_TABLE}}`

Generate a table mapping **task needs** to **actual module directories** detected in the codebase.

Example for a Vue/Quasar project:
```
| Need | Module |
|------|--------|
| API calls | `src/requests/` |
| Route/page entry | `src/pages/` |
| UI parts | `src/components/` |
| State/data | `src/stores/` |
| Business logic | `src/modules/` |
| Shared utility | `src/helpers/` |
| Type definitions | `src/types/` |
| Constants/enums | `src/constant/` |
| Display text | `src/i18n/` |
```

Example for a Rails project:
```
| Need | Module |
|------|--------|
| API endpoint | `app/controllers/` |
| Business logic | `app/operations/` or `app/services/` |
| Input validation | `app/forms/` |
| Data access | `app/models/` |
| Response format | `app/serializers/` |
| Background job | `app/jobs/` |
| Tests | `spec/` |
```

**Use actual directory names from the codebase. Do not guess.**

### `{{IMPLEMENTATION_ORDER}}`

Generate a numbered dependency order based on detected modules. Foundation layers first, consuming layers last.

General pattern:
```
1. types / constants     (foundation — no dependencies)
2. helpers / utilities    (pure functions)
3. requests / services    (data/API layer)
4. hooks / composables    (reusable stateful logic)
5. stores / state         (state management)
6. modules / operations   (business logic)
7. components / views     (UI pieces)
8. pages / controllers    (entry points)
9. i18n / translations    (can be parallel)
```

**Adapt this to the actual modules detected. Remove layers that don't exist. Use actual module names.**

### `{{CODING_DO_RULES}}`

Generate 5-8 bullet points from detected patterns and AGENTS.md rules.

**Always include:**
- Follow existing patterns in the same directory — copy structure from sibling files
- Use absolute imports (if the project uses them)
- Handle loading/error states for async operations
- Keep files/components under reasonable size — decompose if larger

**Add framework-specific:**
- TypeScript: Use types for all props, state, params, return values. No `any`.
- Vue: Use `<script setup>`, `defineProps`/`defineEmits` with types.
- React: Use proper hook patterns, memoization where needed.
- Rails: Use strong parameters, skinny controllers, operations for business logic.
- Python: Use type hints, Pydantic models for validation.

### `{{CODING_DONT_RULES}}`

Generate 5-8 bullet points.

**Always include:**
- Don't add features not in the requirement
- Don't refactor unrelated code while implementing
- Don't skip types or validation
- Don't create new patterns when existing ones cover the case

**Add from AGENTS.md or detected patterns:**
- Import restrictions (forbidden cross-module imports)
- i18n: Don't hardcode user-facing strings
- Framework-specific anti-patterns

### `{{SELF_CHECK_LIST}}`

Generate 6-8 checkbox items.

**Always include:**
- `[ ]` All files placed in correct module and directory
- `[ ]` Naming follows project conventions
- `[ ]` No forbidden imports crossing module boundaries
- `[ ]` Only implemented what was requested — nothing extra

**Add from detected patterns:**
- `[ ]` TypeScript — no `any`, proper types defined
- `[ ]` Async operations have loading/error handling
- `[ ]` i18n used for user-facing text (if applicable)
- `[ ]` Tests written (if project has test convention)
