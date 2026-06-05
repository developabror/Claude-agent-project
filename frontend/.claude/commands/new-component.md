---
description: Build an on-system, typed, accessible, tested React component.
argument-hint: <component name + purpose + which feature slice>
---

Build this component: $ARGUMENTS

1. **Place it** (`react-patterns` skill): the right `src/features/<domain>/components/` (or `components/blocks` if shared); export via the feature's `index.ts` only if it's public.
2. **Build** (`react-engineer`, read `design-system` + `react-patterns`): function component, typed props, tokens-only styling via `cn()`/`cva`, composed from `ui/primitives/blocks`. Semantic HTML + labels + visible focus.
3. **State**: server data via TanStack Query hooks (never raw `useEffect`); client/UI via Zustand; forms via RHF+zod.
4. **Test** (`frontend-test-engineer`): RTL test querying by role/label, covering happy + error/empty states.
5. **Gate**: `design-system-enforcer` (no drift) + `accessibility-auditor` if interactive. `npm run validate` green.

Done when it's typed, on-system, keyboard-operable, tested, and lint/typecheck pass.
