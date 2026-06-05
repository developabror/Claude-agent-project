---
description: Bootstrap this template from empty to a deployable, tested, containerized full-stack app (Spring Boot + React), wiring both sides via the API contract.
argument-hint: [product brief — name, domains, auth model] (optional; will ask if omitted)
disable-model-invocation: true
---

You are the **main-thread conductor** for a 0→production build, running in a **root session**. Follow the `zero-to-prod` skill as the master sequence. Brief: $ARGUMENTS

> **Scope note (read first):** a root session can run root agents/commands and load each side's
> **skills + CLAUDE.md + SETUP doc on demand**, but it **cannot** invoke the child slash-commands
> (`/scaffold-*`) or the child *subagents* (those only load when you launch Claude inside that
> folder). So you have two execution modes — pick one and say which you're using:
> - **(A) Single root session (default):** the main thread does the work itself, reading
>   `backend/BACKEND-SETUP.md` / `frontend/FRONTEND-SETUP.md` and the on-demand side skills as its
>   playbook. Simplest; no specialist subagents.
> - **(B) Per-side sessions (max specialists):** for each side, the operator opens a session there
>   (`cd backend && claude` → `/scaffold-backend`; `cd frontend && claude` → `/scaffold-frontend`)
>   to get that side's specialist agents. The root session still owns planning + contract + compose.

1. **Confirm the brief.** If $ARGUMENTS is thin, delegate to `product-planner` (a root agent) or ask 2–3 crisp questions: product name, base package, core domains/entities, auth model (external IdP vs local), first endpoints. **Define the FE↔BE contract seam before building either side.**

2. **Backend 0→prod.** Execute `backend/BACKEND-SETUP.md` end to end (mode A: drive it yourself with the backend skills loading on demand; mode B: have it run from a backend session via `/scaffold-backend`). End with springdoc emitting and committing `backend/openapi.json`.

3. **Contract.** Run `/contract-sync` (a root command) to generate the frontend API client from `backend/openapi.json`.

4. **Frontend 0→prod.** Execute `frontend/FRONTEND-SETUP.md` end to end (mode A or B), with the data layer consuming the **generated** client.

5. **Compose the system.** Create/verify a top-level `compose.yaml` (Postgres + backend + frontend) so `docker compose up` brings up the whole stack.

6. **Verify.** Both gates green (`./gradlew build`, `npm run validate`), contract gate green, both images healthy, a smoke E2E passes. Show the evidence.

## Rules
- Match depth to the brief — start with the smallest layout that holds; don't scaffold unrequested features.
- Use **plan mode** before large steps. Each step closes with a runnable check, not an assertion.
- Stop and report if any gate is red; never declare "production ready" without green evidence.
- Do **not** push images or deploy — that's the explicit, approved `/ship` step.
