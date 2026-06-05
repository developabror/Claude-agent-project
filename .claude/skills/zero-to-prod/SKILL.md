---
name: zero-to-prod
description: Use at the repo root when bootstrapping a brand-new product from an empty template to a deployable full-stack app — the master sequence that drives the backend and frontend 0→prod scaffolds, wires them via the API contract, and stands up CI/compose. Read when running /build-zero-to-prod.
---

# Zero → Production (master playbook)

The end-to-end sequence to take this template from empty to a running, tested, containerized
full-stack app. The detailed per-side steps live in `backend/BACKEND-SETUP.md` and
`frontend/FRONTEND-SETUP.md` (and the `/scaffold-backend` / `/scaffold-frontend` commands). This is
the conductor.

## Order of operations
1. **Confirm the brief** (delegate `product-planner` if non-trivial): product name, base package
   (`com.example.app` default), domains/entities, auth model (external IdP vs local),
   and the first few endpoints. Define the **contract seam** before building either side.
2. **Backend 0→prod** — run `/scaffold-backend` (or follow `BACKEND-SETUP.md`):
   Gradle multi-module + convention plugin → base deps → `@SpringBootApplication` → domain + JPA +
   Flyway `V1__init.sql` → DTO records + thin controllers + `ProblemDetail` advice → SecurityFilterChain
   → `@ConfigurationProperties` + profiles → Testcontainers integration tests → Actuator + Micrometer OTLP
   + structured logging → layered Dockerfile + compose → CI → **springdoc OpenAPI (commit `openapi.json`)**.
3. **Contract** — `/contract-sync`: generate the frontend client from the backend `openapi.json`.
4. **Frontend 0→prod** — run `/scaffold-frontend` (or follow `FRONTEND-SETUP.md`):
   Vite + strict TS → feature-slice structure → ESLint flat + Prettier + Husky → React Router data mode →
   TanStack Query + axios client (consuming the **generated** client) → Tailwind v4 + shadcn → forms (RHF+zod)
   → Vitest + RTL + MSW + Playwright → a11y/perf budgets → Node→nginx Dockerfile → CI.
5. **Compose the system** — a top-level `compose.yaml` brings up Postgres + backend + frontend (nginx)
   together for one-command local parity; verify the frontend reaches the backend through the contract.
6. **Verify & gate** — both gates green, contract gate green, both images healthy, a smoke E2E passes.
7. **Ship-ready** — `/ship` prepares versions/changelog; deploy is an explicit, approved step.

## Definition of done (the "production setup" bar)
- One command (`docker compose up`) brings up the whole stack locally; health checks green.
- Auth, validation, RFC 9457 errors, migrations, observability, and a synced contract are all in place.
- CI runs lint + typecheck + unit + integration/E2E + scan + build on every PR; images are digest-pinned.
- The repo is reproducible from clean: clone → `docker compose up` → working app.

## Scope control
Match depth to the brief. A thin CRUD service doesn't need Kafka or multi-module sprawl — start with
the smallest layout that holds and let it grow. Don't scaffold features nobody asked for.
