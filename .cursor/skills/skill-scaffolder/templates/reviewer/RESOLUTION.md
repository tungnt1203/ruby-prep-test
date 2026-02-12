# Reviewer — Placeholder Resolution Rules

How to fill each `{{PLACEHOLDER}}` in the reviewer template using detected codebase context.

## Simple Substitutions

| Placeholder | Resolution |
|-------------|------------|
| `{{DESCRIPTION}}` | "Review code for bugs, security, performance, edge cases, best practices, and convention compliance for {detected_stack} projects." |
| `{{DATE}}` | Current date in YYYY-MM-DD format |
| `{{MODULE_GROUPING}}` | List source module directories detected (e.g., "`src/components/`, `src/stores/`, `src/pages/`") |
| `{{SOURCE_DIR}}` | Detected source root (e.g., `src`, `app`, `lib`) |
| `{{TECH_STACK}}` | Detected framework + language (e.g., "Vue 3 / Quasar / TypeScript") |

## Contextual Sections

These require generating project-specific content based on detected stack and patterns. Do NOT use generic filler.

### `{{CORRECTNESS_CHECKS}}`

Generate 5-7 bullet points of **framework-specific** correctness checks.

| Stack | Example Checks |
|-------|---------------|
| Vue 3 | Reactivity pitfalls, async/await misuse, state mutations breaking reactivity, incorrect Pinia patterns |
| React | Hook rules, stale closure, key props, useEffect cleanup |
| Rails | ActiveRecord misuse, callback order, migration safety, N+1 queries |
| Django | ORM misuse, missing migrations, view-template mismatch |
| Go | Goroutine leaks, nil pointer, error not checked |

Base on **actual patterns found in the codebase**, not just framework defaults.

### `{{SECURITY_CHECKS}}`

Generate 5-7 bullet points. **Always include:**
- Hardcoded secrets, API keys, tokens
- User input used without sanitization
- Sensitive data exposed in client-side code or logs
- Missing authentication/authorization checks

**Add framework-specific:**
- Vue: `v-html` XSS, insecure localStorage for tokens
- React: `dangerouslySetInnerHTML`, inline event handlers with user data
- Rails: Mass assignment, CSRF token missing, SQL injection via raw queries
- Django: `|safe` filter misuse, `extra()` / `raw()` queries

### `{{PERFORMANCE_CHECKS}}`

Generate 5-7 bullet points.

**Frontend focus:**
- Unnecessary re-renders, missing computed/memo
- Large data sets without pagination or virtual scrolling
- Missing debounce/throttle on frequent events
- Large imports that should be lazy-loaded
- Redundant API calls

**Backend focus:**
- N+1 queries, missing database indexes
- Synchronous blocking operations
- Missing caching for repeated queries
- Unbounded queries (no LIMIT)

### `{{EDGE_CASE_CHECKS}}`

Generate 5-7 bullet points. Common across all stacks:
- What if the API returns empty data? Error? Timeout?
- What if the array/list is empty?
- What if the user navigates away mid-operation?
- What if input is at boundary values (0, max, negative)?
- What if the user submits twice (double-click)?
- Missing loading/error states for async operations

### `{{BEST_PRACTICE_CHECKS}}`

Generate 5-7 bullet points of framework best practices from detected patterns and AGENTS.md rules.

Examples by stack:
- Vue 3: `<script setup>`, `defineProps`/`defineEmits` with types, `computed` for derived state, component decomposition under 200 lines
- React: Functional components, custom hooks for reusable logic, proper memo usage
- Rails: Skinny controllers, fat models, concerns for shared logic, strong parameters
- Django: Class-based views, form validation, signal usage

### `{{CONVENTION_CHECKS}}`

Generate 4-6 bullet points from AGENTS.md rules:
- File placement: correct module directory
- Naming: follows module convention (suffix, prefix, casing)
- Imports: absolute paths, no forbidden cross-module imports
- i18n: no hardcoded user-facing strings (if applicable)
- Module-specific MUST/MUST NOT rules

If no AGENTS.md exists: use detected patterns from Tier 2 analysis.
