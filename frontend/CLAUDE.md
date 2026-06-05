# CLAUDE.md — frontend (React / TypeScript / Vite)

Launching Claude here loads **only the frontend team** (+ shared root skills). Apply these on every
frontend task unless told otherwise.

## Stack (non-negotiable defaults)
- **React 18 + TypeScript (strict) + Vite**. React Router v7 **data mode**. **TanStack Query v5** (server
  state) + a shared **axios** client. **Zustand** (client/UI/auth). **react-hook-form + zod** (forms).
- **Tailwind v4** (CSS-first `@theme`) + **shadcn/ui** (`ui/primitives/blocks`). **Vitest + RTL + MSW** +
  **Playwright**. ESLint 9 flat config + Prettier + Husky.
- Talks to the Spring Boot API via a **generated** client (from the backend OpenAPI spec — `/wire-api`).

## Agents (delegate proactively)
| Agent | Use for |
|---|---|
| `frontend-architect` | feature-slice structure, routing, state boundaries — *before* coding |
| `react-engineer` | primary implementer: components, pages, forms, routes |
| `data-state-engineer` | TanStack Query + axios client + interceptors + MSW |
| `design-system-enforcer` | guard tokens/shadcn contract; correct drift |
| `frontend-test-engineer` | Vitest + RTL + MSW + Playwright; positive **and** negative |
| `accessibility-auditor` | WCAG 2.2 AA review gate (read-mostly) |
| `web-performance-engineer` | Core Web Vitals + bundle (measure-first) |
| `frontend-security-auditor` | client-side security review gate (read-only) |
| `frontend-build-engineer` | Vite, tooling, Docker→nginx, CI |
| `frontend-reviewer` | adversarial review gate before merge (read-only) |

Use the built-in **Explore** agent for cheap read-only recon before building.

## Commands
`/scaffold-frontend` (0→prod) · `/new-component` · `/new-page` · `/wire-api` (generate the API client).

## Skills (auto-load by description — read the matching one before coding that domain)
`react-patterns` · `typescript-strict` · `data-fetching` · `design-system` · `frontend-testing` ·
`accessibility` · `web-performance` · `frontend-security` · `vite-build`.

## Non-negotiables (surfaced so you don't need to load a skill to recall them)
- **Strict TS**: no `any`, no unjustified `!`. Function components only (no `React.FC`). Files kebab-case, components PascalCase.
- **Feature-slice** layout; **one-directional imports** (`shared → features → pages`); barrel `index.ts` is the only public surface.
- **State boundaries**: server state → TanStack Query (never mirrored into Zustand); raw `useEffect` fetching is banned.
- **Design system is the contract**: tokens only (no raw hex / magic spacing), `cn()` + `cva`, compose `ui/primitives/blocks`.
- **Tokens** in memory / HttpOnly cookies — **never `localStorage`**. Never `dangerouslySetInnerHTML` without DOMPurify. No secrets in `VITE_` vars.
- **Accessibility built-in**: semantic HTML, labels, keyboard operability, visible focus, AA contrast.
- **API types are generated** from the backend OpenAPI spec — never hand-write a shape the spec owns; client validation is UX, the backend re-validates.

## Working principles
Plan non-trivial work first. Close every task with `npm run validate` (typecheck + lint + test)
evidence — never "done" on a red gate. Run `frontend-reviewer` (+ `accessibility-auditor` /
`frontend-security-auditor` as relevant) before merge. Test behavior, not implementation. Smallest
correct diff.

If you add an agent/skill, update the tables above.
