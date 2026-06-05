# FRONTEND-SETUP.md — React 18 / TS / Vite · empty → production

The master, ordered playbook the `/scaffold-frontend` command executes. Each phase names the owning
agent and the skill that holds the detail, and ends with a runnable check (`npm run validate`).

> Stack: React 18 · TypeScript (strict) · Vite · React Router v7 (data mode) · TanStack Query v5 ·
> axios · Zustand · react-hook-form + zod · Tailwind v4 + shadcn/ui · Vitest + RTL + MSW + Playwright ·
> ESLint 9 flat + Prettier + Husky. Talks to the Spring Boot API via a **generated** client.

---

## Phase 0 — Scaffold (`frontend-build-engineer`, skill: `vite-build`)
```bash
npm create vite@latest <app> -- --template react-ts
```
- Max-strict `tsconfig`: `strict`, `noUnusedLocals/Parameters`, `noImplicitReturns`,
  `noFallthroughCasesInSwitch`, `exactOptionalPropertyTypes`; path alias `@/* → src/*`.
- Scripts: `dev/build/preview/typecheck/lint/lint:fix/format/test` + `validate` (typecheck && lint && test).
✅ **Check:** `npm run dev` serves; `npm run typecheck` clean.

## Phase 1 — Tooling (`frontend-build-engineer`)
- **ESLint 9 flat** (`eslint.config.mjs` via `tseslint.config`): js base + typescript-eslint
  (`projectService`) + react/react-hooks/jsx-a11y + simple-import-sort; **`eslint-config-prettier` last**.
- Prettier; Husky pre-commit → lint-staged (eslint --fix + prettier on staged).
- Env: `VITE_`-prefixed across `.env(.development|.production)` + gitignored `.env.local`; `src/env.d.ts`
  typing `ImportMetaEnv`; `src/config/env.ts` validates required vars at startup (fail fast).
✅ **Check:** `npm run lint` clean; commit triggers lint-staged.

## Phase 2 — Structure (`frontend-architect`, skill: `react-patterns`)
```
src/
  features/<domain>/{components,hooks,api,types.ts,index.ts}   # vertical slices
  components/ui/        shared shadcn primitives
  hooks/  lib/  config/  routes/                                # shared layers
```
One-directional imports (`shared → features → pages`); barrel `index.ts` = the only public surface
(the "delete test"). Files kebab-case, components PascalCase.
✅ **Check:** import-sort + the import-direction rule pass lint.

## Phase 3 — Routing / state / forms (`react-engineer` + `data-state-engineer`, skills: `react-patterns`, `data-fetching`)
- React Router v7 **data mode**: `createBrowserRouter` + `RouterProvider`; route `loader`s; route-level
  `React.lazy` + `Suspense`; auth-guard redirects on 401.
- `QueryClient` with sane defaults; the **shared axios client** with request (token) + single-flight 401
  refresh interceptors; map the backend `ProblemDetail` envelope to typed UI errors.
- Forms: react-hook-form + `zodResolver`; types via `z.infer`.
✅ **Check:** a sample protected route loads data via a Query hook; 401 redirects.

## Phase 4 — Wire the API (`data-state-engineer`, command `/wire-api`, skill: `api-contract`)
- `orval.config.ts`: `input → ../backend/openapi.json`, `output → src/lib/api/generated/` (types +
  typed axios client + TanStack Query hooks + MSW handlers). Set `output.override.mutator` →
  `./src/lib/api-client.ts` (export `api`) so generated calls use the **shared** axios instance (auth/refresh
  interceptors), not a fresh one. Run `npx orval`. **Commit** the generated files — they're the contract artifact; never hand-edit them.
✅ **Check:** generated hooks compile; `git diff` clean on a re-run (drift gate).

## Phase 5 — Styling (`react-engineer` + `design-system-enforcer`, skill: `design-system`)
- Tailwind v4 CSS-first `@theme` tokens (`@tailwindcss/vite`, no `tailwind.config.js`); shadcn/ui via CLI
  organized `ui/ → primitives/ → blocks/`; `cn()` helper. Tokens only — no raw hex / magic spacing.
✅ **Check:** a sample page renders on-system; the design-system validation checklist passes.

## Phase 6 — Testing (`frontend-test-engineer`, skill: `frontend-testing`)
- Vitest + jsdom + RTL + user-event + jest-dom; MSW at the network layer (reuse the generated handlers).
- Playwright for the critical journey (auth + core flow); cache browsers in CI.
- Query by role/label; cover happy + error/empty/401 paths; behavior, not implementation.
✅ **Check:** `npm run test` green; a Playwright smoke flow passes.

## Phase 7 — Quality gates (`accessibility-auditor`, `web-performance-engineer`, `frontend-security-auditor`)
- **A11y:** eslint-jsx-a11y + `@axe-core/react` + axe test assertions; WCAG 2.2 AA; manual keyboard/SR pass.
- **Perf:** route splitting + Vite `manualChunks`; budgets LCP<2.5s / INP<200ms / CLS<0.1; bundle analysis in CI.
- **Security:** no `localStorage` tokens, no unsanitized HTML sinks, no secrets in `VITE_`, `npm audit` clean, CSP.
✅ **Check:** axe clean, CWV within budget, security checklist green.

## Phase 8 — Package & CI (`frontend-build-engineer`, skill: `vite-build`)
- Multi-stage Dockerfile: `node:24-slim` build → `nginx:stable-alpine` runtime, **non-root**, SPA
  `try_files … /index.html`, gzip/cache headers, `HEALTHCHECK`, `.dockerignore`. Runtime env via `window.__ENV__`.
- GitHub Actions: cached install → typecheck → lint → vitest → playwright → build → buildx push (sha+semver).
✅ **Check:** `docker build` serves the SPA; deep-link fallback works; CI gates green.

## Phase 9 — Review gate (`frontend-reviewer`)
Adversarial review in fresh context; resolve every Critical before done.

---

### Definition of done (the "production" bar)
`npm run validate` green · generated API client in sync with the backend · React Router data mode ·
TanStack Query owning server state · on-system design tokens · Vitest+RTL+MSW + a Playwright smoke ·
WCAG 2.2 AA · CWV budgets met · non-root nginx image with SPA fallback · CI with required gates.
