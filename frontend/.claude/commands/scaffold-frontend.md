---
description: Scaffold this frontend from empty to a deployable React 18 + TS + Vite SPA following FRONTEND-SETUP.md.
argument-hint: [app name + key pages] (optional; will ask if omitted)
disable-model-invocation: true
---

Scaffold the frontend 0→production. Follow **`FRONTEND-SETUP.md`** in full as the ordered playbook. Brief: $ARGUMENTS

Delegate each phase to the owning specialist; use plan mode before large steps; close each phase with a runnable check (`npm run validate`).

1. **Scaffold** (`frontend-build-engineer`): `npm create vite@latest -- --template react-ts`, max-strict `tsconfig`, split scripts (`dev/build/typecheck/lint/test/validate`).
2. **Tooling** (`frontend-build-engineer`): ESLint 9 flat config (+ react/hooks/jsx-a11y/import-sort, prettier last), Prettier, Husky + lint-staged, `VITE_` env + typed `src/config/env.ts`.
3. **Structure** (`frontend-architect`): feature-slice `src/` layout, one-directional imports, barrel `index.ts` per feature.
4. **Routing/state/forms** (`react-engineer` + `data-state-engineer`): React Router v7 data mode + lazy routes; `QueryClient` + axios client with auth/refresh interceptors; RHF + zod.
5. **Wire the API** (`/wire-api`): generate the typed client/hooks from the backend `openapi.json` (`data-state-engineer`).
6. **Styling** (`react-engineer` + `design-system-enforcer`): Tailwind v4 `@theme` tokens + shadcn/ui (`ui/primitives/blocks`), `cn()`.
7. **Testing** (`frontend-test-engineer`): Vitest + RTL + MSW; Playwright for the critical journey.
8. **Quality gates** (`accessibility-auditor`, `web-performance-engineer`, `frontend-security-auditor`): a11y (jsx-a11y + axe), CWV budgets, security checklist.
9. **Package + CI** (`frontend-build-engineer`): Node→nginx multi-stage Dockerfile (non-root, SPA fallback), GitHub Actions.
10. **Review gate** (`frontend-reviewer`): resolve every Critical.

Done when `npm run validate` is green, `docker build` serves the SPA with deep-link fallback, and the app reaches the backend through the generated client.
